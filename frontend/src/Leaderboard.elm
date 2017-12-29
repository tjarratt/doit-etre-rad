module Leaderboard
    exposing
        ( Model
        , Msg
        , LeaderboardItem
        , update
        , view
        , defaultModel
        , leaderboardItemDecoder
        )

import Html exposing (Html)
import Html.CssHelpers
import Html.Events
import Http
import IndexCss
import Html
import Html.Attributes
import Http
import Json.Decode as JD
import Urls exposing (adminApiUrl)


type Msg
    = Noop
    | TypePassword String
    | RequestToBackend
    | ReceiveFromBackend (Result Http.Error (List LeaderboardItem))


type alias LeaderboardItem =
    { userUuid : String
    , phraseCount : Int
    }


type alias Model =
    { authenticated : Bool
    , typedPassword : String
    , items : List LeaderboardItem
    }


defaultModel : Model
defaultModel =
    { authenticated = False
    , typedPassword = ""
    , items = []
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        TypePassword password ->
            ( { model | typedPassword = password }, Cmd.none )

        RequestToBackend ->
            let
                config =
                    { method = "GET"
                    , headers = [ Http.header "X-Password" model.typedPassword ]
                    , url = adminApiUrl
                    , body = Http.emptyBody
                    , expect = Http.expectJson <| JD.list leaderboardItemDecoder
                    , timeout = Nothing
                    , withCredentials = False
                    }

                request =
                    Http.request config
            in
                ( { model | typedPassword = "" }, Http.send ReceiveFromBackend request )

        ReceiveFromBackend (Ok leaderboardItems) ->
            ( { model | authenticated = True, items = leaderboardItems }, Cmd.none )

        ReceiveFromBackend _ ->
            ( model, Cmd.none )


view : Model -> (Msg -> a) -> Html a
view model wrapper =
    let
        innerView =
            case model.authenticated of
                True ->
                    leaderboardView model wrapper

                False ->
                    passwordFieldView wrapper
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


leaderboardView : Model -> (Msg -> a) -> Html a
leaderboardView model wrapper =
    Html.ul
        [ id IndexCss.Leaderboard ]
    <|
        List.map leaderboardItemView model.items


leaderboardItemView : LeaderboardItem -> Html abs
leaderboardItemView item =
    Html.li
        []
        [ Html.span [ class [ IndexCss.LeaderboardItem ] ] [ Html.text item.userUuid ]
        , Html.span [ class [ IndexCss.LeaderboardItem ] ] [ Html.text <| toString item.phraseCount ]
        ]


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"


leaderboardItemDecoder : JD.Decoder LeaderboardItem
leaderboardItemDecoder =
    JD.map2 LeaderboardItem
        (JD.field "userUuid" JD.string)
        (JD.field "phraseCount" JD.int)
