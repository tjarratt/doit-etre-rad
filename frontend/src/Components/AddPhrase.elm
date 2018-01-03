module Components.AddPhrase
    exposing
        ( Model
        , Msg
        , OutMsg(..)
        , update
        , view
        , defaultModel
        )

import Activities exposing (Activity(..))
import Css.Helpers exposing (identifierToString)
import Html exposing (Html)
import Html.Attributes
import Html.CssHelpers
import Html.Events
import IndexCss
import Phrases


type alias Model =
    { typedPhrase : String, activity : Activity }


type Msg
    = TypePhrase String
    | UserDidClickAddButton


type OutMsg
    = Noop
    | NewPhraseCreated Phrases.Phrase


defaultModel : Activity -> Model
defaultModel activity =
    { activity = activity, typedPhrase = "" }


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        TypePhrase string ->
            ( { model | typedPhrase = string }, Cmd.none, Noop )

        UserDidClickAddButton ->
            if String.length model.typedPhrase == 0 then
                ( model, Cmd.none, Noop )
            else
                clearFormAndSubmitPhrase model


clearFormAndSubmitPhrase : Model -> ( Model, Cmd Msg, OutMsg )
clearFormAndSubmitPhrase model =
    let
        newPhrase =
            Phrases.Unsaved { content = model.typedPhrase, translation = "" }
    in
        ( { model | typedPhrase = "" }, Cmd.none, NewPhraseCreated newPhrase )


view : Model -> (Msg -> a) -> Html a
view model wrapper =
    addWordForm model wrapper


addWordForm : Model -> (Msg -> a) -> Html a
addWordForm model wrapper =
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
                [ Html.text <| inputLabel model.activity ]
            , Html.input
                [ id IndexCss.AddWordInput
                , Html.Attributes.placeholder <| phrasePlaceholder model.activity
                , Html.Attributes.class "form-control"
                , Html.Events.onInput (\string -> wrapper <| TypePhrase string)
                , Html.Attributes.value model.typedPhrase
                ]
                []
            , Html.button
                [ id IndexCss.AddWordSaveButton
                , Html.Events.onClick <| wrapper UserDidClickAddButton
                , Html.Attributes.class "btn btn-default"
                ]
                [ Html.text "Add" ]
            ]
        ]


inputLabel : Activity -> String
inputLabel currentActivity =
    case currentActivity of
        EnglishToFrench ->
            "Add an english phrase"

        FrenchToEnglish ->
            "Add a french phrase"

        _ ->
            "whoops impossible state"


phrasePlaceholder : Activity -> String
phrasePlaceholder activity =
    case activity of
        EnglishToFrench ->
            "colorless green ideas sleep furiously"

        FrenchToEnglish ->
            "à tout de suite"

        _ ->
            ""


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"
