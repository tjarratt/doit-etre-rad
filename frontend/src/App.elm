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
    | PracticeFrenchPhrases
    | TypePhraseUpdate String
    | AddPhraseToPractice
    | ReceiveFromLocalStorage ( String, Maybe JD.Value )
    | DidSaveToLocalStorage JD.Value
    | ReceiveUserUuid (Maybe String)
    | ReceivePhrasesFromBackend (Result Http.Error (List SavedPhrase))
    | ReceivePhraseFromBackend (Result Http.Error SavedPhrase)


{-| Represents the current state of the application
-}
type alias Model =
    { userUuid : Maybe Uuid.Uuid
    , currentSeed : Seed
    , currentActivity : Maybe TranslationActivity
    , wordToAdd : String
    , frenchPhrases : List Phrase
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
    , frenchPhrases = []
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
                , Html.div [ id IndexCss.Modes ]
                    [ Html.button
                        [ Html.Events.onClick PracticeFrenchPhrases
                        , Html.Attributes.class "btn btn-default"
                        ]
                        [ Html.text "French Phrases" ]
                    ]
                ]

        Just FrenchToEnglish ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing French phrases" ]
                , addWordForm model
                , listOfWords model
                ]

        Just _ ->
            Html.div [] [ Html.text "Not done yet ..." ]


listOfWords : Model -> Html Msg
listOfWords model =
    Html.ul [ Html.Attributes.id "word-list" ] <|
        List.map
            (\content -> Html.li [] [ Html.text content ])
            (List.map
                (\phrase -> phraseToString phrase)
                model.frenchPhrases
            )


addWordForm : Model -> Html Msg
addWordForm model =
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
                [ Html.text "Add a french phrase" ]
            , Html.input
                [ id IndexCss.AddWordInput
                , Html.Attributes.placeholder "à tout de suite"
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


{-| Modifies application state in response to messages from components
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
            ( model, sendPhraseToBackend model.userUuid jsonValue )

        ReceiveUserUuid (Just uuidString) ->
            let
                uuid =
                    Uuid.fromString uuidString
            in
                ( { model | userUuid = uuid }
                , getPhrasesFromBackend uuid
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

        PracticeFrenchPhrases ->
            ( { model | currentActivity = Just FrenchToEnglish }
            , Cmd.batch [ LocalStorage.getUserUuid "", LocalStorage.getItem "frenchPhrases" ]
            )

        ReceivePhraseFromBackend _ ->
            ( model, Cmd.none )

        ReceivePhrasesFromBackend (Ok response) ->
            let
                savedPhrases =
                    List.map (\p -> Saved p) response
            in
                ( { model
                    | frenchPhrases = merge model.frenchPhrases savedPhrases
                  }
                , Cmd.none
                )

        ReceivePhrasesFromBackend _ ->
            ( model, Cmd.none )

        Noop ->
            ( model, Cmd.none )


handleValueFromLocalStorage : Model -> String -> Maybe JE.Value -> ( Model, Cmd msg )
handleValueFromLocalStorage model key maybeValue =
    case ( key, maybeValue ) of
        ( "frenchPhrases", Just value ) ->
            case JD.decodeValue (JD.list LocalStorage.phraseDecoder) value of
                Ok phrases ->
                    let
                        updatedPhrases =
                            merge model.frenchPhrases phrases
                    in
                        ( { model
                            | frenchPhrases = updatedPhrases
                          }
                        , Cmd.none
                        )

                _ ->
                    ( model, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


getPhrasesFromBackend : Maybe Uuid.Uuid -> Cmd Msg
getPhrasesFromBackend maybeUuid =
    case maybeUuid of
        Nothing ->
            Cmd.none

        Just userUuid ->
            let
                uuidStr =
                    Uuid.toString userUuid

                url =
                    "/api/phrases/french"

                headers =
                    [ Http.header "X-User-Token" uuidStr ]

                expect =
                    Http.expectJson <| JD.list phraseDecoder

                config =
                    { method = "GET"
                    , headers = headers
                    , url = url
                    , body = Http.emptyBody
                    , expect = expect
                    , timeout = Nothing
                    , withCredentials = False
                    }

                request =
                    Http.request config
            in
                Http.send ReceivePhrasesFromBackend request


sendPhraseToBackend : Maybe Uuid.Uuid -> JE.Value -> Cmd Msg
sendPhraseToBackend uuid phrase =
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
                    , url = "/api/phrases/french"
                    , body = Http.jsonBody jsonValue
                    , expect = Http.expectJson phraseDecoder
                    , timeout = Nothing
                    , withCredentials = False
                    }

                request =
                    Http.request config
            in
                Http.send ReceivePhraseFromBackend request


phraseDecoder : JD.Decoder SavedPhrase
phraseDecoder =
    JD.map2 SavedPhrase
        (JD.field "uuid" JD.string)
        (JD.field "content" JD.string)


updateFrenchPhrases : Model -> ( Model, Cmd Msg )
updateFrenchPhrases model =
    let
        updatedPhrases =
            merge model.frenchPhrases [ Unsaved model.wordToAdd ]

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
            LocalStorage.saveFrenchPhrases ( updatedPhrases, model.wordToAdd )
    in
        ( { model
            | wordToAdd = ""
            , frenchPhrases = updatedPhrases
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
