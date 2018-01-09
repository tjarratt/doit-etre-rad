module Components.Leaderboard
    exposing
        ( Model
        , Msg
        , update
        , view
        , defaultModel
        )

{-| Provides a component for the "leaderboard" page of the app


# Elm Architecture bits

@docs Model, Msg, update, view, defaultModel

-}

import Html exposing (Html)
import Html.CssHelpers
import Html.Events
import Http
import IndexCss
import Html
import Html.Attributes
import Http
import Navigation
import Components.Leaderboard.JSON exposing (LeaderboardItem, decoder, errorDecoder)
import Urls exposing (adminApiUrl)


{-| possible messages that can be handles internally
-}
type Msg
    = Noop
    | NavigateBack
    | TypePassword String
    | RequestToBackend
    | ReceiveFromBackend (Result Http.Error (List LeaderboardItem))


type State
    = Unauthenticated (Maybe String)
    | Authenticated (List LeaderboardItem)


{-| state of the component
-}
type alias Model =
    { state : State
    , typedPassword : String
    }


{-| how the model initially works - used to embed the component into a larger app
-}
defaultModel : Model
defaultModel =
    { state = Unauthenticated Nothing
    , typedPassword = ""
    }


{-| should be called by the presenting application/component's update function
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        NavigateBack ->
            ( model, Navigation.back 1 )

        TypePassword password ->
            ( { model | typedPassword = password }, Cmd.none )

        RequestToBackend ->
            requestLeaderboardFromBackend model

        ReceiveFromBackend (Ok leaderboardItems) ->
            ( { model | state = Authenticated leaderboardItems }, Cmd.none )

        ReceiveFromBackend (Err error) ->
            handleBackendError model error


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


handleBackendError : Model -> Http.Error -> ( Model, Cmd Msg )
handleBackendError model error =
    let
        messageToShow =
            case error of
                Http.BadStatus response ->
                    errorDecoder response.body

                _ ->
                    "something bad happened, bro"
    in
        ( { model | state = Unauthenticated <| Just messageToShow }, Cmd.none )


{-| should be called by the presenting application/component
interestingly enough, this needs to be generic over a given Msg type
because we cannot anticipate all possible messages this will need to send
in the component that presents us
-}
view : Model -> Html Msg
view model =
    let
        innerView =
            case model.state of
                Authenticated items ->
                    leaderboardView items

                Unauthenticated Nothing ->
                    passwordFieldView

                Unauthenticated (Just errorMessage) ->
                    Html.div []
                        [ passwordFieldView
                        , errorMessageView errorMessage
                        ]
    in
        Html.div []
            [ Html.div [ class [ IndexCss.CenterMe ] ] [ Html.h1 [] [ Html.text "Should you really be here ?" ] ]
            , Html.button [ id IndexCss.Back, Html.Events.onClick NavigateBack, Html.Attributes.class "btn btn-link" ] [ Html.text "↩ Back" ]
            , Html.div [ id IndexCss.AdminSection ] [ innerView ]
            ]


passwordFieldView : Html Msg
passwordFieldView =
    Html.form [ Html.Attributes.action "javascript:void(0)" ]
        [ Html.input
            [ id IndexCss.PasswordField
            , Html.Events.onInput TypePassword
            , Html.Attributes.placeholder "<secret password>"
            , Html.Attributes.class "form-control"
            ]
            []
        , Html.button
            [ Html.Events.onClick RequestToBackend
            , Html.Attributes.class "btn btn-primary"
            ]
            [ Html.text "Submit" ]
        ]


errorMessageView : String -> Html Msg
errorMessageView string =
    Html.div [ id IndexCss.Errors ]
        [ Html.text string ]


leaderboardView : List LeaderboardItem -> Html Msg
leaderboardView items =
    Html.ul
        [ id IndexCss.Leaderboard ]
    <|
        List.map leaderboardItemView items


leaderboardItemView : LeaderboardItem -> Html Msg
leaderboardItemView item =
    Html.li
        []
        [ Html.span [ class [ IndexCss.LeaderboardItem ] ] [ Html.text item.userUuid ]
        , Html.span [ class [ IndexCss.LeaderboardItem ] ] [ Html.text <| toString item.phraseCount ]
        ]


{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"
