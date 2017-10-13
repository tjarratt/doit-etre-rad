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

import Dom
import Json.Decode as JD
import Json.Encode as JE
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import List
import Ports.LocalStorage as LocalStorage
import Random.Pcg exposing (Seed, initialSeed)
import Task
import Uuid
import UuidGenerator


--- App supports multiple activities
--- it is nice to know which the user is currently doing


type TranslationActivity
    = FrenchToEnglish
    | EnglishToFrench
    | DifferentiateFrenchWords


type alias Phrase =
    { uuid : Maybe String
    , content : String
    }


type Msg
    = Noop
    | PracticeFrenchPhrases
    | TypePhraseUpdate String
    | AddPhraseToPractice
    | ReceiveFromLocalStorage ( String, Maybe JD.Value )
    | DidSaveToLocalStorage JD.Value
    | ReceiveUserUuid (Maybe String)
    | ReceivePhrasesFromBackend (Result Http.Error (List Phrase))
    | ReceivePhraseFromBackend (Result Http.Error Phrase)


{-| Represents the current state of the application
-}
type alias Model =
    { userUuid : Maybe Uuid.Uuid
    , currentSeed : Seed
    , currentActivity : Maybe TranslationActivity
    , wordToAdd : String
    , frenchPhrases : List String
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
    }


{-| Returns the HTMl to be rendered based on the current application state
-}
view : Model -> Html Msg
view model =
    case model.currentActivity of
        Nothing ->
            Html.div []
                [ Html.h1 [] [ Html.text "I want to practice" ]
                , Html.div [ Html.Attributes.id "modes" ]
                    [ Html.button [ Html.Events.onClick PracticeFrenchPhrases ]
                        [ Html.text "French Phrases" ]
                    ]
                ]

        Just FrenchToEnglish ->
            Html.div []
                [ Html.h1 [] [ Html.text "Practicing French phrases" ]
                , Html.ul [ Html.Attributes.id "word-list" ] <|
                    List.map
                        (\phrase -> Html.li [] [ Html.text phrase ])
                        model.frenchPhrases
                , Html.div [ Html.Attributes.id "add-word" ]
                    [ Html.input
                        [ Html.Attributes.id "add-word--input"
                        , Html.Attributes.placeholder "Add a French phrase"
                        , Html.Events.onInput TypePhraseUpdate
                        , Html.Attributes.value model.wordToAdd
                        ]
                        []
                    , Html.button
                        [ Html.Events.onClick AddPhraseToPractice ]
                        [ Html.text "Submit" ]
                    ]
                ]

        Just _ ->
            Html.div [] [ Html.text "Not done yet ..." ]


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

        ReceiveFromLocalStorage ( "frenchPhrases", Just value ) ->
            case JD.decodeValue (JD.list JD.string) value of
                Ok frenchPhrases ->
                    ( { model | frenchPhrases = frenchPhrases }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ReceiveFromLocalStorage ( _, _ ) ->
            ( model, Cmd.none )

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

        ReceivePhrasesFromBackend _ ->
            ( model, Cmd.none )

        Noop ->
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


phraseDecoder : JD.Decoder Phrase
phraseDecoder =
    JD.map2 Phrase
        (JD.field "content" (JD.nullable JD.string))
        (JD.field "uuid" JD.string)


updateFrenchPhrases : Model -> ( Model, Cmd Msg )
updateFrenchPhrases model =
    let
        updatedPhrases =
            List.append model.frenchPhrases [ model.wordToAdd ]

        -- refactor opportunity: extract this into a module
        -- we gain better testability and don't need to worry about failure
        -- and we can assert it was called with the right args :(
        focusTask =
            Task.onError (\_ -> Task.succeed ()) (Dom.focus "add-word--input")

        focusInput =
            Task.perform (\_ -> Noop) focusTask

        saveInLocalStorage =
            LocalStorage.setItem
                ( "frenchPhrases"
                , JE.list <| List.map JE.string updatedPhrases
                , model.wordToAdd
                )
    in
        ( { model
            | wordToAdd = ""
            , frenchPhrases = List.append model.frenchPhrases [ model.wordToAdd ]
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
