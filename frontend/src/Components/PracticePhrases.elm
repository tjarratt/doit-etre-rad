module Components.PracticePhrases
    exposing
        ( Msg
        , Msg(..)
        , Model
        , defaultModel
        , update
        , loadComponent
        , view
        , subscriptions
        )

import Activities exposing (Activity(..))
import Components.AddPhrase as AddPhrase
import Css.Helpers exposing (identifierToString)
import Dom
import Html exposing (Html)
import Html.Attributes
import Html.CssHelpers
import Html.Events
import Http
import IndexCss
import Json.Decode as JD
import Json.Encode as JE
import Phrases exposing (Phrase)
import Ports.Bootstrap as Bootstrap
import Ports.LocalStorage as LocalStorage
import Task
import Urls
import Uuid exposing (Uuid)


type Msg
    = Noop
    | ComponentDidLoad
    | TypeTranslationUpdate String
    | StartEditingTranslation PhraseViewModel
    | AddTranslationToPhrase PhraseViewModel
    | FlipPhraseCard PhraseViewModel
    | ReceiveFromLocalStorage ( String, Maybe JD.Value )
    | DidSaveToLocalStorage JD.Value
    | ReceivePhrasesFromBackend (Result Http.Error (List Phrases.SavedPhrase))
    | ReceivePhraseFromBackend (Result Http.Error Phrases.SavedPhrase)
    | SetAddPhrase AddPhrase.Msg


type alias Model =
    { userUuid : Uuid
    , addPhrase : AddPhrase.Model
    , phrases : List PhraseViewModel
    , currentTranslation : String
    , activity : Activity
    }


type alias PhraseViewModel =
    { phrase : Phrases.Phrase
    , selected : Bool
    , editing : Bool
    }


mergePhraseViewModels : Model -> List Phrase -> Model
mergePhraseViewModels model phrases =
    let
        existingPhrases =
            List.map (\p -> p.phrase) model.phrases

        mergedPhrases =
            Phrases.merge existingPhrases phrases

        phraseViewModels =
            List.map
                (\p -> { phrase = p, selected = False, editing = False })
                mergedPhrases
    in
        { model | phrases = phraseViewModels }


defaultModel : Uuid -> Activity -> Model
defaultModel uuid activity =
    { phrases = []
    , currentTranslation = ""
    , userUuid = uuid
    , activity = activity
    , addPhrase = AddPhrase.defaultModel activity
    }



{- UPDATE (and its many friends) -}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        ComponentDidLoad ->
            ( model, fetchPhrasesFromLocalStorageAndRenderTooltips model )

        SetAddPhrase addPhraseMsg ->
            let
                ( phraseModel, childMsg, outMsg ) =
                    AddPhrase.update
                        addPhraseMsg
                        model.addPhrase

                updatedModel =
                    { model | addPhrase = phraseModel }

                ( newModel, newCmd ) =
                    processAddPhraseMsg outMsg updatedModel
            in
                ( newModel
                , Cmd.batch
                    [ Cmd.map SetAddPhrase childMsg
                    , newCmd
                    ]
                )

        FlipPhraseCard phrase ->
            flipCardMatchingPhrase model phrase

        StartEditingTranslation phrase ->
            startEditingMatchingPhrase model phrase

        TypeTranslationUpdate translation ->
            ( { model | currentTranslation = translation }, Cmd.none )

        AddTranslationToPhrase phrase ->
            if String.length model.currentTranslation == 0 then
                ( model, Cmd.none )
            else
                persistCurrentTranslation model phrase

        ReceiveFromLocalStorage ( key, value ) ->
            handleValueFromLocalStorage model key value

        DidSaveToLocalStorage encodedPhrase ->
            let
                command =
                    case JD.decodeValue LocalStorage.phraseDecoder encodedPhrase of
                        Ok phrase ->
                            sendPhraseToBackend
                                model.activity
                                model.userUuid
                                phrase

                        _ ->
                            Cmd.none
            in
                ( model, Cmd.batch [ Bootstrap.showTooltips (), command ] )

        ReceivePhraseFromBackend (Ok phrase) ->
            let
                updatedModel =
                    mergePhraseViewModels model [ Phrases.Saved phrase ]
            in
                ( updatedModel, Bootstrap.showTooltips () )

        ReceivePhraseFromBackend _ ->
            ( model, Cmd.none )

        ReceivePhrasesFromBackend (Ok response) ->
            let
                newPhrases =
                    List.map (\p -> Phrases.Saved p) response

                updatedModel =
                    mergePhraseViewModels model newPhrases
            in
                ( updatedModel, Bootstrap.showTooltips () )

        ReceivePhrasesFromBackend _ ->
            ( model, Cmd.none )


loadComponent : () -> Cmd Msg
loadComponent _ =
    Task.perform identity <| Task.succeed ComponentDidLoad


fetchPhrasesFromLocalStorageAndRenderTooltips : Model -> Cmd Msg
fetchPhrasesFromLocalStorageAndRenderTooltips model =
    Cmd.batch
        [ LocalStorage.getItem <| localStorageKey model.activity
        , Bootstrap.showTooltips ()
        ]


localStorageKey : Activity -> String
localStorageKey activity =
    case activity of
        EnglishToFrench ->
            "englishPhrases"

        FrenchToEnglish ->
            "frenchPhrases"

        DifferentiateFrenchWords ->
            "whoops"


processAddPhraseMsg : AddPhrase.OutMsg -> Model -> ( Model, Cmd Msg )
processAddPhraseMsg outMsg model =
    case outMsg of
        AddPhrase.Noop ->
            ( model, Cmd.none )

        AddPhrase.NewPhraseCreated newPhrase ->
            persistCurrentPhrase model newPhrase


persistCurrentPhrase : Model -> Phrases.Phrase -> ( Model, Cmd Msg )
persistCurrentPhrase model newPhrase =
    let
        updatedModel =
            mergePhraseViewModels
                model
                [ newPhrase ]

        updatedPhrases =
            List.map (\p -> p.phrase) updatedModel.phrases

        idToFocus =
            (identifierToString "" IndexCss.AddWordInput)

        -- TODO (refactor opportunity): extract focus into a module
        -- we gain better testability and don't need to worry about failure
        -- and we can assert it was called with the right args :(
        focusTask =
            Task.onError (\_ -> Task.succeed ()) (Dom.focus idToFocus)

        focusInput =
            Task.perform (\_ -> Noop) focusTask

        saveInLocalStorage =
            case model.activity of
                EnglishToFrench ->
                    LocalStorage.saveEnglishPhrases ( updatedPhrases, newPhrase )

                FrenchToEnglish ->
                    LocalStorage.saveFrenchPhrases ( updatedPhrases, newPhrase )

                _ ->
                    Cmd.none
    in
        ( updatedModel
        , Cmd.batch [ focusInput, saveInLocalStorage ]
        )


flipCardMatchingPhrase : Model -> PhraseViewModel -> ( Model, Cmd Msg )
flipCardMatchingPhrase model viewModel =
    let
        updatedViewModel =
            List.map
                (\p ->
                    if Phrases.phraseEqual p.phrase viewModel.phrase then
                        { p | selected = (not p.selected), editing = False }
                    else
                        { p | selected = False, editing = False }
                )
                model.phrases
    in
        ( { model | phrases = updatedViewModel }, Cmd.none )


startEditingMatchingPhrase : Model -> PhraseViewModel -> ( Model, Cmd Msg )
startEditingMatchingPhrase model viewModel =
    let
        updatedViewModel =
            List.map
                (\p ->
                    if Phrases.phraseEqual p.phrase viewModel.phrase then
                        { p | editing = True }
                    else
                        { p | editing = False }
                )
                model.phrases

        phraseTranslation =
            Phrases.translationOf viewModel.phrase
    in
        ( { model
            | currentTranslation = phraseTranslation
            , phrases = updatedViewModel
          }
        , Cmd.none
        )


persistCurrentTranslation : Model -> PhraseViewModel -> ( Model, Cmd Msg )
persistCurrentTranslation model viewModel =
    let
        phrase =
            viewModel.phrase

        translatedPhrase =
            Phrases.translate phrase model.currentTranslation

        updatedViewModel =
            List.map
                (\v ->
                    if Phrases.phraseEqual phrase v.phrase then
                        { v
                            | editing = False
                            , phrase = translatedPhrase
                        }
                    else
                        v
                )
                model.phrases

        phrases =
            List.map (\p -> p.phrase) updatedViewModel

        localStorageCommand =
            case model.activity of
                EnglishToFrench ->
                    LocalStorage.saveEnglishPhrases ( phrases, translatedPhrase )

                FrenchToEnglish ->
                    LocalStorage.saveFrenchPhrases ( phrases, translatedPhrase )

                _ ->
                    Cmd.none
    in
        ( { model
            | phrases = updatedViewModel
            , currentTranslation = ""
          }
        , localStorageCommand
        )


handleValueFromLocalStorage : Model -> String -> Maybe JE.Value -> ( Model, Cmd Msg )
handleValueFromLocalStorage model key maybeValue =
    case ( key, maybeValue ) of
        ( _, Just value ) ->
            handleDecodedJsonFromLocalStorage model value

        ( _, _ ) ->
            ( model, Cmd.none )


handleDecodedJsonFromLocalStorage : Model -> JE.Value -> ( Model, Cmd Msg )
handleDecodedJsonFromLocalStorage model json =
    case JD.decodeValue (JD.list LocalStorage.phraseDecoder) json of
        Ok phrases ->
            ( mergePhraseViewModels model phrases
            , Cmd.batch [ Bootstrap.showTooltips (), getPhrasesFromBackend model ]
            )

        _ ->
            ( model, Cmd.none )


sendPhraseToBackend : Activity -> Uuid.Uuid -> Phrases.Phrase -> Cmd Msg
sendPhraseToBackend currentActivity uuid phrase =
    let
        uuidStr =
            Uuid.toString uuid

        method =
            case phrase of
                Phrases.Saved _ ->
                    "PUT"

                Phrases.Unsaved _ ->
                    "POST"

        endpoint =
            urlForCurrentActivityAndPhrase currentActivity phrase

        jsonValue =
            case phrase of
                Phrases.Saved p ->
                    JE.object
                        [ ( "uuid", JE.string p.uuid )
                        , ( "content", JE.string p.content )
                        , ( "translation", JE.string p.translation )
                        ]

                Phrases.Unsaved p ->
                    JE.object
                        [ ( "content", JE.string p.content )
                        , ( "translation", JE.string p.translation )
                        ]

        config =
            { method = method
            , headers = [ Http.header "X-User-Token" uuidStr ]
            , url = endpoint
            , body = Http.jsonBody jsonValue
            , expect = Http.expectJson savedPhraseDecoder
            , timeout = Nothing
            , withCredentials = False
            }

        request =
            Http.request config
    in
        Http.send ReceivePhraseFromBackend request


urlForCurrentActivityAndPhrase : Activity -> Phrases.Phrase -> String
urlForCurrentActivityAndPhrase activity phrase =
    let
        baseURL =
            baseUrlForCurrentActivity activity
    in
        case phrase of
            Phrases.Saved p ->
                baseURL ++ "/" ++ p.uuid

            Phrases.Unsaved _ ->
                baseURL


baseUrlForCurrentActivity : Activity -> String
baseUrlForCurrentActivity activity =
    case activity of
        EnglishToFrench ->
            Urls.englishPhrasesUrl

        FrenchToEnglish ->
            Urls.frenchPhrasesUrl

        _ ->
            "/api/phrases/whoops"


savedPhraseDecoder : JD.Decoder Phrases.SavedPhrase
savedPhraseDecoder =
    JD.map3 Phrases.SavedPhrase
        (JD.field "uuid" JD.string)
        (JD.field "content" JD.string)
        (JD.field "translation" JD.string)


getPhrasesFromBackend : Model -> Cmd Msg
getPhrasesFromBackend model =
    let
        uuidStr =
            Uuid.toString model.userUuid

        headers =
            [ Http.header "X-User-Token" uuidStr ]

        expect =
            Http.expectJson <| JD.list savedPhraseDecoder

        config =
            { method = "GET"
            , headers = headers
            , url = readUrlForCurrentActivity model.activity
            , body = Http.emptyBody
            , expect = expect
            , timeout = Nothing
            , withCredentials = False
            }

        request =
            Http.request config
    in
        Http.send ReceivePhrasesFromBackend request


readUrlForCurrentActivity : Activity -> String
readUrlForCurrentActivity activity =
    baseUrlForCurrentActivity activity



{- View -}


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"


view : Model -> Html Msg
view model =
    case model.activity of
        FrenchToEnglish ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing French phrases" ]
                , AddPhrase.view model.addPhrase SetAddPhrase
                , phraseListView model
                ]

        EnglishToFrench ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing English phrases" ]
                , AddPhrase.view model.addPhrase SetAddPhrase
                , phraseListView model
                ]

        DifferentiateFrenchWords ->
            Html.div [] [ Html.text "Not done yet ..." ]


phraseListView : Model -> Html Msg
phraseListView model =
    Html.ul
        [ id IndexCss.PhraseList ]
    <|
        List.map
            (\phrase ->
                viewForPhrase model phrase
            )
            model.phrases


viewForPhrase : Model -> PhraseViewModel -> Html Msg
viewForPhrase model phrase =
    let
        buttonAction =
            if phrase.selected then
                Noop
            else
                FlipPhraseCard phrase
    in
        Html.li
            [ class [ IndexCss.PhraseListItem ] ]
            [ Html.div
                [ class [ IndexCss.CardContainer ]
                , Html.Events.onClick buttonAction
                ]
                [ Html.div
                    [ class <| cssClassesForCardFlipper phrase ]
                    [ frontViewForPhrase phrase
                    , backViewForPhrase model phrase
                    ]
                ]
            ]


cssClassesForCardFlipper : PhraseViewModel -> List IndexCss.CssClasses
cssClassesForCardFlipper viewModel =
    if viewModel.selected then
        [ IndexCss.CardFlipper, IndexCss.Flip ]
    else
        [ IndexCss.CardFlipper ]


frontViewForPhrase : PhraseViewModel -> Html Msg
frontViewForPhrase viewModel =
    Html.div [ class [ IndexCss.CardFront ] ]
        [ case viewModel.phrase of
            Phrases.Saved _ ->
                Html.text <| Phrases.toString viewModel.phrase

            Phrases.Unsaved _ ->
                Html.div []
                    [ Html.span
                        [ Html.Attributes.class "text-warning" ]
                        [ Html.text <| Phrases.toString viewModel.phrase ]
                    , Html.a
                        [ Html.Attributes.href "#"
                        , Html.Attributes.attribute "data-toggle" "tooltip"
                        , Html.Attributes.attribute "data-placement" "bottom"
                        , Html.Attributes.title offlineModeTooltip
                        ]
                        [ Html.span
                            [ class [ IndexCss.OfflineIndicator ]
                            , Html.Attributes.class "glyphicon glyphicon-exclamation-sign"
                            ]
                            []
                        ]
                    ]
        ]


backViewForPhrase : Model -> PhraseViewModel -> Html Msg
backViewForPhrase model viewModel =
    let
        buttonAction =
            if viewModel.editing then
                AddTranslationToPhrase viewModel
            else
                StartEditingTranslation viewModel

        buttonText =
            if viewModel.editing then
                "Save"
            else
                "Edit"
    in
        Html.div
            [ class [ IndexCss.CardBack ] ]
            [ Html.form
                [ Html.Attributes.action "javascript:void(0)" ]
                [ viewForPhraseTranslationText model viewModel
                , Html.div []
                    [ Html.button
                        [ class [ IndexCss.AddTranslationButton ]
                        , Html.Events.onClick buttonAction
                        , Html.Attributes.class "btn btn-default"
                        ]
                        [ Html.text buttonText ]
                    , Html.button
                        [ class [ IndexCss.CancelTranslationButton ]
                        , Html.Events.onClick <| FlipPhraseCard viewModel
                        , Html.Attributes.class "btn btn-default"
                        ]
                        [ Html.text "Cancel" ]
                    ]
                ]
            ]


viewForPhraseTranslationText : Model -> PhraseViewModel -> Html Msg
viewForPhraseTranslationText model viewModel =
    if viewModel.editing then
        Html.input
            [ class [ IndexCss.AddPhraseTranslation ]
            , Html.Events.onInput TypeTranslationUpdate
            , Html.Attributes.placeholder "..."
            , Html.Attributes.class "form-control"
            , Html.Attributes.value model.currentTranslation
            ]
            []
    else
        let
            currentTranslation =
                Phrases.translationOf viewModel.phrase

            labelText =
                if String.isEmpty currentTranslation then
                    "..."
                else
                    currentTranslation
        in
            Html.label
                []
                [ Html.text <| labelText ]


offlineModeTooltip : String
offlineModeTooltip =
    "This phrase is saved locally, but has not been saved to our server."



{- SUBSCRIPTIONS -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ LocalStorage.getItemResponse ReceiveFromLocalStorage
        , LocalStorage.setItemResponse DidSaveToLocalStorage
        ]