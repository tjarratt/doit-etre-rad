module App
    exposing
        ( ApplicationState
        , Msg
        , defaultModel
        , view
        , update
        , subscriptions
        )

{-| This is an application to aide in practicing french and english.
For more information, checkout <https://github.com/tjarratt/doit-etre-rad>


# global application state

@docs ApplicationState, Msg


# initial application state

@docs defaultModel


# rendering HTML

@docs view


# modifying application state

@docs update


# subscribe to updates

@docs subscriptions

-}

import Css.Helpers exposing (identifierToString)
import Dom
import Json.Decode as JD
import Json.Encode as JE
import Html exposing (Html)
import Html.Attributes
import Html.CssHelpers
import Html.Events
import Http
import IndexCss
import List
import Ports.Bootstrap as Bootstrap
import Ports.LocalStorage as LocalStorage
import Random.Pcg exposing (Seed, initialSeed)
import Task
import Leaderboard
import Phrases
import Urls
import Uuid
import UuidGenerator


-- App supports multiple activities
-- translating from english to french
-- translating from french to english
-- differentiating similar, but different words
-- viewing leaderboard


type Activity
    = FrenchToEnglish
    | EnglishToFrench
    | DifferentiateFrenchWords
    | ViewLeaderboard


{-| Represents all of the state changes in the application
-}
type Msg
    = Noop
    | ReceiveUserUuid (Maybe String)
    | PracticeFrenchPhrases
    | PracticeEnglishPhrases
    | TypePhraseUpdate String
    | TypeTranslationUpdate String
    | StartEditingTranslation PhraseViewModel
    | AddTranslationToPhrase PhraseViewModel
    | AddPhraseToPractice
    | FlipPhraseCard PhraseViewModel
    | ReceiveFromLocalStorage ( String, Maybe JD.Value )
    | DidSaveToLocalStorage JD.Value
    | ReceivePhrasesFromBackend (Result Http.Error (List Phrases.SavedPhrase))
    | ReceivePhraseFromBackend (Result Http.Error Phrases.SavedPhrase)
    | NavigateToLeaderboard
    | SetLeaderboard Leaderboard.Msg



{-
   AddPhraseMsg
   =================
   TypePhraseUpdate
   AddPhraseToPracice

   PhraseCardMsg
   ================
   FlipPhraseCard
   StartEditingTranslation
   TypeTranslationUpdate
   AddTranslationToPhrase
-}


{-| Represents the current state of the application
-}
type alias ApplicationState =
    { userUuid : Maybe Uuid.Uuid
    , currentSeed : Seed
    , currentActivity : Maybe Activity
    , wordToAdd : String
    , currentTranslation : String
    , phrases : List PhraseViewModel
    , leaderboard : Leaderboard.Model
    }



{-
   userUuid -> activity -> Phrases

   currentActivity + useruuid ...
   userUuid Maybe or ...
   phrases should also logically be a part of this...

   wordToAdd belongs on an AddPhrase "component"

   currentTranslation belongs on a "PhraseCard" component
-}


type alias PhraseViewModel =
    { phrase : Phrases.Phrase
    , selected : Bool
    , editing : Bool
    }


{-| Represents the initial state of the application
-}
defaultModel : Int -> ApplicationState
defaultModel seed =
    { userUuid = Nothing
    , currentSeed = initialSeed seed
    , currentActivity = Nothing
    , wordToAdd = ""
    , currentTranslation = ""
    , phrases = []
    , leaderboard = Leaderboard.defaultModel
    }


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"


{-| Returns the HTMl to be rendered based on the current application state
-}
view : ApplicationState -> Html Msg
view model =
    case model.currentActivity of
        Nothing ->
            Html.div [ id IndexCss.LandingPage ]
                [ Html.h1 [] [ Html.text "I want to practice" ]
                , activityButton "French words and phrases" "practiceFrench" PracticeFrenchPhrases
                , activityButton "English words and phrases" "practiceEnglish" PracticeEnglishPhrases
                , landingPageButton
                ]

        Just FrenchToEnglish ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing French phrases" ]
                , addWordForm "à tout de suite" model
                , phraseListView model model.phrases
                ]

        Just EnglishToFrench ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing English phrases" ]
                , addWordForm "colorless green ideas sleep furiously" model
                , phraseListView model model.phrases
                ]

        Just DifferentiateFrenchWords ->
            Html.div [] [ Html.text "Not done yet ..." ]

        Just ViewLeaderboard ->
            Leaderboard.view model.leaderboard (\msg -> SetLeaderboard msg)


activityButton : String -> String -> Msg -> Html Msg
activityButton title idAttr msg =
    Html.div [ id IndexCss.Modes ]
        [ Html.button
            [ Html.Events.onClick msg
            , Html.Attributes.id idAttr
            , Html.Attributes.class "btn btn-default"
            ]
            [ Html.text title ]
        ]


landingPageButton : Html Msg
landingPageButton =
    Html.button
        [ id IndexCss.SecretButton
        , Html.Events.onClick NavigateToLeaderboard
        ]
        [ Html.text "shh..." ]


phraseListView : ApplicationState -> List PhraseViewModel -> Html Msg
phraseListView model phrases =
    Html.ul
        [ id IndexCss.PhraseList ]
    <|
        List.map
            (\phrase ->
                viewForPhrase model phrase
            )
            phrases


viewForPhrase : ApplicationState -> PhraseViewModel -> Html Msg
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
                , Html.Events.onClick <| buttonAction
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


backViewForPhrase : ApplicationState -> PhraseViewModel -> Html Msg
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
                        , Html.Events.onClick <| buttonAction
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


viewForPhraseTranslationText : ApplicationState -> PhraseViewModel -> Html Msg
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


addWordForm : String -> ApplicationState -> Html Msg
addWordForm placeholder model =
    Html.form
        [ Html.Attributes.action "javascript:void(0)"
        , id IndexCss.AddPhraseForm
        ]
        [ Html.div
            [ Html.Attributes.id "add-word"
            , Html.Attributes.class "text-center"
            ]
            [ Html.label
                [ id IndexCss.AddWordLabel
                , Html.Attributes.for (identifierToString "" IndexCss.AddWordInput)
                ]
                [ Html.text (inputLabel model.currentActivity) ]
            , Html.input
                [ id IndexCss.AddWordInput
                , Html.Attributes.placeholder placeholder
                , Html.Attributes.class "form-control"
                , Html.Events.onInput TypePhraseUpdate
                , Html.Attributes.value model.wordToAdd
                ]
                []
            , Html.button
                [ id IndexCss.AddWordSaveButton
                , Html.Events.onClick AddPhraseToPractice
                , Html.Attributes.class "btn btn-default"
                ]
                [ Html.text "Add" ]
            ]
        ]


inputLabel : Maybe Activity -> String
inputLabel currentActivity =
    case currentActivity of
        Just EnglishToFrench ->
            "Add an english phrase"

        Just FrenchToEnglish ->
            "Add a french phrase"

        _ ->
            "Impossible state whoops !"


{-| Modifies application state in response to messages from components
-}
update : Msg -> ApplicationState -> ( ApplicationState, Cmd Msg )
update msg model =
    case msg of
        PracticeFrenchPhrases ->
            startActivity FrenchToEnglish "frenchPhrases" model

        PracticeEnglishPhrases ->
            startActivity EnglishToFrench "englishPhrases" model

        TypePhraseUpdate phrase ->
            ( { model | wordToAdd = phrase }, Cmd.none )

        AddPhraseToPractice ->
            if String.length model.wordToAdd == 0 then
                ( model, Cmd.none )
            else
                persistCurrentPhrase model

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
                                model.currentActivity
                                model.userUuid
                                phrase

                        _ ->
                            Cmd.none
            in
                ( model, command )

        ReceiveUserUuid (Just uuidString) ->
            let
                uuid =
                    (Uuid.fromString uuidString)
            in
                ( { model | userUuid = uuid }
                , getPhrasesFromBackend model.currentActivity uuid
                )

        ReceiveUserUuid Nothing ->
            let
                ( uuid, nextSeed ) =
                    UuidGenerator.next model.currentSeed
            in
                ( { model
                    | userUuid = Just uuid
                    , currentSeed = nextSeed
                  }
                , LocalStorage.setUserUuid <| Uuid.toString uuid
                )

        ReceivePhraseFromBackend (Ok phrase) ->
            let
                updatedModel =
                    mergePhraseViewModels model [ Phrases.Saved phrase ]
            in
                ( updatedModel, Bootstrap.showTooltips () )

        ReceivePhraseFromBackend _ ->
            ( model, Bootstrap.showTooltips () )

        ReceivePhrasesFromBackend (Ok response) ->
            let
                newPhrases =
                    List.map (\p -> Phrases.Saved p) response

                updatedModel =
                    mergePhraseViewModels model newPhrases
            in
                ( updatedModel, Cmd.none )

        ReceivePhrasesFromBackend _ ->
            ( model, Bootstrap.showTooltips () )

        NavigateToLeaderboard ->
            ( { model | currentActivity = Just ViewLeaderboard }, Cmd.none )

        SetLeaderboard leaderboardMsg ->
            let
                ( leaderboard, msg ) =
                    Leaderboard.update
                        leaderboardMsg
                        model.leaderboard
            in
                ( { model | leaderboard = leaderboard }, Cmd.map SetLeaderboard msg )

        Noop ->
            ( model, Cmd.none )


startActivity : Activity -> String -> ApplicationState -> ( ApplicationState, Cmd msg )
startActivity activity localStorageKey model =
    ( { model | currentActivity = Just activity }
    , Cmd.batch
        [ LocalStorage.getUserUuid ()
        , LocalStorage.getItem localStorageKey
        , Bootstrap.showTooltips ()
        ]
    )


handleValueFromLocalStorage : ApplicationState -> String -> Maybe JE.Value -> ( ApplicationState, Cmd msg )
handleValueFromLocalStorage model key maybeValue =
    case ( key, maybeValue ) of
        ( _, Just value ) ->
            case JD.decodeValue (JD.list LocalStorage.phraseDecoder) value of
                Ok phrases ->
                    ( mergePhraseViewModels model phrases, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


getPhrasesFromBackend : Maybe Activity -> Maybe Uuid.Uuid -> Cmd Msg
getPhrasesFromBackend currentActivity maybeUuid =
    case maybeUuid of
        Nothing ->
            Cmd.none

        Just userUuid ->
            let
                uuidStr =
                    Uuid.toString userUuid

                headers =
                    [ Http.header "X-User-Token" uuidStr ]

                expect =
                    Http.expectJson <| JD.list savedPhraseDecoder

                config =
                    { method = "GET"
                    , headers = headers
                    , url = readUrlForCurrentActivity currentActivity
                    , body = Http.emptyBody
                    , expect = expect
                    , timeout = Nothing
                    , withCredentials = False
                    }

                request =
                    Http.request config
            in
                Http.send ReceivePhrasesFromBackend request


sendPhraseToBackend : Maybe Activity -> Maybe Uuid.Uuid -> Phrases.Phrase -> Cmd Msg
sendPhraseToBackend currentActivity uuid phrase =
    case uuid of
        Nothing ->
            (Cmd.none)

        Just uuid ->
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


urlForCurrentActivityAndPhrase : Maybe Activity -> Phrases.Phrase -> String
urlForCurrentActivityAndPhrase currentActivity phrase =
    let
        baseURL =
            baseUrlForCurrentActivity currentActivity
    in
        case phrase of
            Phrases.Saved p ->
                baseURL ++ "/" ++ p.uuid

            Phrases.Unsaved _ ->
                baseURL


baseUrlForCurrentActivity : Maybe Activity -> String
baseUrlForCurrentActivity currentActivity =
    case currentActivity of
        Just EnglishToFrench ->
            Urls.englishPhrasesUrl

        Just FrenchToEnglish ->
            Urls.frenchPhrasesUrl

        _ ->
            "/api/phrases/whoops"


readUrlForCurrentActivity : Maybe Activity -> String
readUrlForCurrentActivity currentActivity =
    baseUrlForCurrentActivity currentActivity


savedPhraseDecoder : JD.Decoder Phrases.SavedPhrase
savedPhraseDecoder =
    JD.map3 Phrases.SavedPhrase
        (JD.field "uuid" JD.string)
        (JD.field "content" JD.string)
        (JD.field "translation" JD.string)


flipCardMatchingPhrase : ApplicationState -> PhraseViewModel -> ( ApplicationState, Cmd Msg )
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


startEditingMatchingPhrase : ApplicationState -> PhraseViewModel -> ( ApplicationState, Cmd Msg )
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
            | phrases = updatedViewModel
            , currentTranslation = phraseTranslation
          }
        , Cmd.none
        )


persistCurrentPhrase : ApplicationState -> ( ApplicationState, Cmd Msg )
persistCurrentPhrase model =
    let
        newPhrase =
            Phrases.Unsaved { content = model.wordToAdd, translation = "" }

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
            case model.currentActivity of
                Just EnglishToFrench ->
                    LocalStorage.saveEnglishPhrases ( updatedPhrases, newPhrase )

                Just FrenchToEnglish ->
                    LocalStorage.saveFrenchPhrases ( updatedPhrases, newPhrase )

                _ ->
                    Cmd.none
    in
        ( { updatedModel | wordToAdd = "" }
        , Cmd.batch [ focusInput, saveInLocalStorage ]
        )


persistCurrentTranslation : ApplicationState -> PhraseViewModel -> ( ApplicationState, Cmd Msg )
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
            case model.currentActivity of
                Just EnglishToFrench ->
                    LocalStorage.saveEnglishPhrases ( phrases, translatedPhrase )

                Just FrenchToEnglish ->
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


mergePhraseViewModels : ApplicationState -> List Phrases.Phrase -> ApplicationState
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


{-| Subscribes to updates from the outside world (ooh, spooky!)
-}
subscriptions : ApplicationState -> Sub Msg
subscriptions model =
    Sub.batch
        [ LocalStorage.getItemResponse ReceiveFromLocalStorage
        , LocalStorage.setItemResponse DidSaveToLocalStorage
        , LocalStorage.getUserUuidResponse ReceiveUserUuid
        ]


type alias Flags =
    { seed : Int }


init : Flags -> ( ApplicationState, Cmd Msg )
init flags =
    ( defaultModel flags.seed, Cmd.none )


main : Program Flags ApplicationState Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
