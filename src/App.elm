module App
    exposing
        ( Model
        , defaultModel
        , view
        , update
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

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events


type TranslationActivity
    = FrenchToEnglish
    | EnglishToFrench
    | DifferentiateFrenchWords


{-| Represents the current state of the application
-}
type alias Model =
    { currentActivity : Maybe TranslationActivity
    , wordToAdd : String
    , frenchPhrasesToTranslate : List String
    }


type Msg
    = PracticeFrenchPhrases
    | TypePhraseUpdate String
    | AddPhraseToPractice


{-| Represents the initial state of the application
-}
defaultModel : Model
defaultModel =
    { currentActivity = Nothing, wordToAdd = "", frenchPhrasesToTranslate = [] }


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
                        model.frenchPhrasesToTranslate
                , Html.div [ Html.Attributes.id "add-word" ]
                    [ Html.input
                        [ Html.Attributes.placeholder "Add a French phrase"
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
        PracticeFrenchPhrases ->
            ( { model | currentActivity = Just FrenchToEnglish }, Cmd.none )

        TypePhraseUpdate phrase ->
            ( { model | wordToAdd = phrase }, Cmd.none )

        AddPhraseToPractice ->
            ( { model
                | wordToAdd = ""
                , frenchPhrasesToTranslate = [ model.wordToAdd ]
              }
            , Cmd.none
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []


frenchPhrases : List String
frenchPhrases =
    [ "anguille sous roche" ]
