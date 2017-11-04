module App
    exposing
        ( Model
        , defaultModel
        , view
        , update
        , subscriptions
        )

{-| This is an application to aide in practicing french and english.
For more information, checkout <https://github.com/tjarratt/doit-etre-rad>


# global application state

@docs Model


# initial application state

@docs defaultModel


# rendering HTML

@docs view


# modifying application state

@docs update


# subscribe to updates

@docs subscriptions

-}

import Css
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
import Phrases exposing (..)
import Uuid
import UuidGenerator


--- App supports multiple activities
--- it is nice to know which the user is currently doing


type TranslationActivity
    = FrenchToEnglish
    | EnglishToFrench
    | DifferentiateFrenchWords


type Msg
    = Noop
    | ReceiveUserUuid (Maybe String)
    | PracticeFrenchPhrases
    | PracticeEnglishPhrases
    | TypePhraseUpdate String
    | AddPhraseToPractice
    | ReceiveFromLocalStorage ( String, Maybe JD.Value )
    | DidSaveToLocalStorage JD.Value
    | ReceivePhrasesFromBackend (Result Http.Error (List SavedPhrase))
    | ReceivePhraseFromBackend (Result Http.Error SavedPhrase)


{-| Represents the current state of the application
-}
type alias Model =
    { userUuid : Maybe Uuid.Uuid
    , currentSeed : Seed
    , currentActivity : Maybe TranslationActivity
    , wordToAdd : String
    , phrases : List Phrase
    , errors : Int
    }


{-| Represents the initial state of the application
-}
defaultModel : Int -> Model
defaultModel seed =
    { userUuid = Nothing
    , currentSeed = initialSeed seed
    , currentActivity = Nothing
    , wordToAdd = ""
    , phrases = []
    , errors = 0
    }


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"


{-| Returns the HTMl to be rendered based on the current application state
-}
view : Model -> Html Msg
view model =
    case model.currentActivity of
        Nothing ->
            Html.div []
                [ Html.h1 [] [ Html.text "I want to practice" ]
                , activityButton "French words and phrases" "practiceFrench" PracticeFrenchPhrases
                , activityButton "English words and phrases" "practiceEnglish" PracticeEnglishPhrases
                ]

        Just FrenchToEnglish ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing French phrases" ]
                , addWordForm "à tout de suite" model
                , listOfWords model.phrases
                ]

        Just EnglishToFrench ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing English phrases" ]
                , addWordForm "colorless green ideas sleep furiously" model
                , listOfWords model.phrases
                ]

        Just _ ->
            Html.div [] [ Html.text "Not done yet ..." ]


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


listOfWords : List Phrase -> Html Msg
listOfWords phrases =
    Html.ul [ Html.Attributes.id "word-list" ] <|
        List.map
            (\phrase ->
                Html.li
                    [ class [ IndexCss.PhraseListItem ] ]
                    (listItemForPhrase phrase)
            )
            phrases


listItemForPhrase : Phrase -> List (Html Msg)
listItemForPhrase phrase =
    case phrase of
        Saved _ ->
            [ Html.text <| phraseToString phrase ]

        Unsaved _ ->
            [ Html.span
                [ Html.Attributes.class "text-warning" ]
                [ Html.text <| phraseToString phrase ]
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


offlineModeTooltip : String
offlineModeTooltip =
    "This phrase is saved locally, but has not been saved to our server."


addWordForm : String -> Model -> Html Msg
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
                [ Html.text "Save" ]
            ]
        ]


inputLabel : Maybe TranslationActivity -> String
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
update : Msg -> Model -> ( Model, Cmd Msg )
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
                updateFrenchPhrases model

        ReceiveFromLocalStorage ( key, value ) ->
            handleValueFromLocalStorage model key value

        DidSaveToLocalStorage jsonValue ->
            ( model, sendPhraseToBackend model.currentActivity model.userUuid jsonValue )

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
                savedPhrase =
                    Saved phrase
            in
                ( { model
                    | phrases = merge model.phrases [ savedPhrase ]
                  }
                , Bootstrap.showTooltips ()
                )

        ReceivePhraseFromBackend _ ->
            ( model, Bootstrap.showTooltips () )

        ReceivePhrasesFromBackend (Ok response) ->
            let
                savedPhrases =
                    List.map (\p -> Saved p) response
            in
                ( { model
                    | phrases = merge model.phrases savedPhrases
                  }
                , Cmd.none
                )

        ReceivePhrasesFromBackend _ ->
            ( model, Bootstrap.showTooltips () )

        Noop ->
            ( model, Cmd.none )


startActivity : TranslationActivity -> String -> Model -> ( Model, Cmd msg )
startActivity activity localStorageKey model =
    ( { model | currentActivity = Just activity }
    , Cmd.batch
        [ LocalStorage.getUserUuid ()
        , LocalStorage.getItem localStorageKey
        , Bootstrap.showTooltips ()
        ]
    )


handleValueFromLocalStorage : Model -> String -> Maybe JE.Value -> ( Model, Cmd msg )
handleValueFromLocalStorage model key maybeValue =
    case ( key, maybeValue ) of
        ( _, Just value ) ->
            case JD.decodeValue (JD.list LocalStorage.phraseDecoder) value of
                Ok phrases ->
                    ( { model | phrases = merge model.phrases phrases }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


getPhrasesFromBackend : Maybe TranslationActivity -> Maybe Uuid.Uuid -> Cmd Msg
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
                    Http.expectJson <| JD.list phraseDecoder

                config =
                    { method = "GET"
                    , headers = headers
                    , url = urlForCurrentActivity currentActivity
                    , body = Http.emptyBody
                    , expect = expect
                    , timeout = Nothing
                    , withCredentials = False
                    }

                request =
                    Http.request config
            in
                Http.send ReceivePhrasesFromBackend request


sendPhraseToBackend : Maybe TranslationActivity -> Maybe Uuid.Uuid -> JE.Value -> Cmd Msg
sendPhraseToBackend currentActivity uuid phrase =
    case uuid of
        Nothing ->
            (Cmd.none)

        Just uuid ->
            let
                uuidStr =
                    Uuid.toString uuid

                jsonValue =
                    JE.object [ ( "content", phrase ) ]

                config =
                    { method = "POST"
                    , headers = [ Http.header "X-User-Token" uuidStr ]
                    , url = urlForCurrentActivity currentActivity
                    , body = Http.jsonBody jsonValue
                    , expect = Http.expectJson phraseDecoder
                    , timeout = Nothing
                    , withCredentials = False
                    }

                request =
                    Http.request config
            in
                Http.send ReceivePhraseFromBackend request


urlForCurrentActivity : Maybe TranslationActivity -> String
urlForCurrentActivity currentActivity =
    case currentActivity of
        Just EnglishToFrench ->
            "/api/phrases/english"

        Just FrenchToEnglish ->
            "/api/phrases/french"

        _ ->
            "/api/phrases/whoops"


phraseDecoder : JD.Decoder SavedPhrase
phraseDecoder =
    JD.map2 SavedPhrase
        (JD.field "uuid" JD.string)
        (JD.field "content" JD.string)


updateFrenchPhrases : Model -> ( Model, Cmd Msg )
updateFrenchPhrases model =
    let
        updatedPhrases =
            merge model.phrases [ Unsaved model.wordToAdd ]

        inputId =
            (identifierToString "" IndexCss.AddWordInput)

        -- TODO (refactor opportunity): extract this into a module
        -- we gain better testability and don't need to worry about failure
        -- and we can assert it was called with the right args :(
        focusTask =
            Task.onError (\_ -> Task.succeed ()) (Dom.focus inputId)

        focusInput =
            Task.perform (\_ -> Noop) focusTask

        saveInLocalStorage =
            case model.currentActivity of
                Just EnglishToFrench ->
                    LocalStorage.saveEnglishPhrases ( updatedPhrases, model.wordToAdd )

                Just FrenchToEnglish ->
                    LocalStorage.saveFrenchPhrases ( updatedPhrases, model.wordToAdd )

                _ ->
                    Cmd.none
    in
        ( { model
            | wordToAdd = ""
            , phrases = updatedPhrases
          }
        , Cmd.batch [ focusInput, saveInLocalStorage ]
        )


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Flags =
    { seed : Int }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( defaultModel flags.seed, Cmd.none )


{-| Subscribes to updates from the outside world (ooh, spooky!)
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ LocalStorage.getItemResponse ReceiveFromLocalStorage
        , LocalStorage.setItemResponse DidSaveToLocalStorage
        , LocalStorage.getUserUuidResponse ReceiveUserUuid
        ]
