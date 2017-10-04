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
import List
import Ports.LocalStorage as LocalStorage
import Task


--- App supports multiple activities
--- it is nice to know which the user is currently doing


type TranslationActivity
    = FrenchToEnglish
    | EnglishToFrench
    | DifferentiateFrenchWords


{-| Represents the current state of the application
-}
type alias Model =
    { currentActivity : Maybe TranslationActivity
    , wordToAdd : String
    , frenchPhrases : List String
    }


type Msg
    = Noop
    | PracticeFrenchPhrases
    | TypePhraseUpdate String
    | AddPhraseToPractice
    | ReceiveFromLocalStorage ( String, Maybe JD.Value )


{-| Represents the initial state of the application
-}
defaultModel : Model
defaultModel =
    { currentActivity = Nothing, wordToAdd = "", frenchPhrases = [] }


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

        PracticeFrenchPhrases ->
            ( { model | currentActivity = Just FrenchToEnglish }
            , LocalStorage.getItem "frenchPhrases"
            )

        Noop ->
            ( model, Cmd.none )


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
                )
    in
        ( { model
            | wordToAdd = ""
            , frenchPhrases = List.append model.frenchPhrases [ model.wordToAdd ]
          }
        , Cmd.batch [ focusInput, saveInLocalStorage ]
        )


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( defaultModel, Cmd.none )


{-| Subscribes to updates from the outside world (ooh, spooky!)
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.getItemResponse ReceiveFromLocalStorage
