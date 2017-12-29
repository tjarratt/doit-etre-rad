module Leaderboard
    exposing
        ( Model
        , Msg
        , update
        , view
        , defaultModel
        )

import Html exposing (Html)
import Html.CssHelpers
import Html.Events
import Http
import IndexCss
import Html
import Html.Attributes
import Http
import Leaderboard.JSON
    exposing
        ( Error
        , LeaderboardItem
        , LeaderboardResult(..)
        , decoder
        )
import Urls exposing (adminApiUrl)


type Msg
    = Noop
    | TypePassword String
    | RequestToBackend
    | ReceiveFromBackend (Result Http.Error LeaderboardResult)


type State
    = Unauthenticated (Maybe String)
    | Authenticated (List LeaderboardItem)


type alias Model =
    { state : State
    , typedPassword : String
    }


defaultModel : Model
defaultModel =
    { state = Unauthenticated Nothing
    , typedPassword = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        TypePassword password ->
            ( { model | typedPassword = password }, Cmd.none )

        RequestToBackend ->
            requestLeaderboardFromBackend model

        ReceiveFromBackend (Ok (Success leaderboardItems)) ->
            ( { model | state = Authenticated leaderboardItems }, Cmd.none )

        ReceiveFromBackend (Ok (Failure json)) ->
            ( { model | state = Unauthenticated <| Just json.error }, Cmd.none )

        ReceiveFromBackend (Err json) ->
            ( { model | state = Unauthenticated <| Just "something bad happened, bro" }, Cmd.none )


requestLeaderboardFromBackend : Model -> ( Model, Cmd Msg )
requestLeaderboardFromBackend model =
    let
        config =
            { method = "GET"
            , headers = [ Http.header "X-Password" model.typedPassword ]
            , url = adminApiUrl
            , body = Http.emptyBody
            , expect = Http.expectJson <| decoder
            , timeout = Nothing
            , withCredentials = False
            }

        request =
            Http.request config
    in
        ( { model | typedPassword = "" }, Http.send ReceiveFromBackend request )


view : Model -> (Msg -> a) -> Html a
view model wrapper =
    let
        innerView =
            case model.state of
                Authenticated items ->
                    leaderboardView items

                Unauthenticated Nothing ->
                    passwordFieldView wrapper

                Unauthenticated (Just errorMessage) ->
                    Html.div []
                        [ passwordFieldView wrapper
                        , errorMessageView errorMessage
                        ]
    in
        Html.div
            [ id IndexCss.AdminSection ]
            [ innerView
            ]


passwordFieldView : (Msg -> a) -> Html a
passwordFieldView wrapper =
    Html.form [ Html.Attributes.action "javascript:void(0)" ]
        [ Html.input
            [ id IndexCss.PasswordField
            , Html.Events.onInput (\string -> wrapper <| TypePassword string)
            , Html.Attributes.placeholder "<secret password>"
            , Html.Attributes.class "form-control"
            ]
            []
        , Html.button
            [ Html.Events.onClick <| wrapper RequestToBackend ]
            [ Html.text "Submit" ]
        ]


errorMessageView : String -> Html a
errorMessageView string =
    Html.div [ id IndexCss.Errors ]
        [ Html.text string ]


leaderboardView : List LeaderboardItem -> Html a
leaderboardView items =
    Html.ul
        [ id IndexCss.Leaderboard ]
    <|
        List.map leaderboardItemView items


leaderboardItemView : LeaderboardItem -> Html abs
leaderboardItemView item =
    Html.li
        []
        [ Html.span [ class [ IndexCss.LeaderboardItem ] ] [ Html.text item.userUuid ]
        , Html.span [ class [ IndexCss.LeaderboardItem ] ] [ Html.text <| toString item.phraseCount ]
        ]


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"
