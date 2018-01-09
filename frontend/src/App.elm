module App
    exposing
        ( ApplicationState
        , Msg
        , init
        , view
        , update
        , subscriptions
        )

{-| This is an application to aide in practicing french and english.
For more information, checkout <https://github.com/tjarratt/doit-etre-rad>


# global application state

@docs ApplicationState, Msg


# initial application state

@docs init


# rendering HTML

@docs view


# modifying application state

@docs update


# subscribe to updates

@docs subscriptions

-}

import Activities exposing (Activity(..))
import Components.Leaderboard as Leaderboard
import Components.PracticePhrases as PracticePhrases
import Html exposing (Html)
import Html.Attributes
import Html.CssHelpers
import Html.Events
import IndexCss
import Navigation
import Ports.LocalStorage as LocalStorage
import Uuid


{-| Represents all of the state changes in the application
-}
type Msg
    = Noop
    | UrlChange Navigation.Location
    | ReceiveUserUuid String
    | NavigateToPracticeFrenchPhrases
    | NavigateToPracticeEnglishPhrases
    | NavigateToLeaderboard
    | SetLeaderboard Leaderboard.Msg
    | SetPracticePhrases PracticePhrases.Msg


{-| Represents the current state of the application
-}
type alias ApplicationState =
    { userUuid : Maybe Uuid.Uuid
    , leaderboard : Leaderboard.Model
    , currentPage : CurrentPage
    }


{-| Represents the page the user is currently viewing
-}
type CurrentPage
    = LandingPage
    | ViewLeaderboard
    | ViewActivity Activity PracticePhrases.Model


{-| Represents the initial state of the application
-}
defaultModel : Int -> ApplicationState
defaultModel seed =
    { currentPage = LandingPage
    , userUuid = Nothing
    , leaderboard = Leaderboard.defaultModel
    }


{-| helper functions to make it easier to leverage our type-safe CSS
-}
{ id, class, classList } =
    Html.CssHelpers.withNamespace "index"


{-| Returns the HTMl to be rendered based on the current application state
-}
view : ApplicationState -> Html Msg
view model =
    case model.currentPage of
        LandingPage ->
            Html.div [ id IndexCss.LandingPage ]
                [ Html.h1 [] [ Html.text "I want to practice" ]
                , activityButton "French words and phrases" IndexCss.PracticeFrench NavigateToPracticeFrenchPhrases
                , activityButton "English words and phrases" IndexCss.PracticeEnglish NavigateToPracticeEnglishPhrases
                , landingPageButton
                ]

        ViewLeaderboard ->
            Html.map SetLeaderboard <| Leaderboard.view model.leaderboard

        ViewActivity activity childModel ->
            Html.map SetPracticePhrases <| PracticePhrases.view childModel


activityButton : String -> IndexCss.CssIds -> Msg -> Html Msg
activityButton title elementId msg =
    Html.div [ id IndexCss.Modes ]
        [ Html.button
            [ Html.Events.onClick msg
            , id elementId
            , Html.Attributes.class "btn btn-default"
            ]
            [ Html.text title ]
        ]


landingPageButton : Html Msg
landingPageButton =
    Html.div [ id IndexCss.SecretButton ]
        [ Html.button
            [ Html.Attributes.class "btn btn-default"
            , Html.Events.onClick NavigateToLeaderboard
            ]
            [ Html.text "shh..." ]
        ]


{-| Modifies application state in response to messages from components
-}
update : Msg -> ApplicationState -> ( ApplicationState, Cmd Msg )
update msg model =
    case msg of
        NavigateToPracticeFrenchPhrases ->
            startActivity FrenchToEnglish model

        NavigateToPracticeEnglishPhrases ->
            startActivity EnglishToFrench model

        NavigateToLeaderboard ->
            ( { model | currentPage = ViewLeaderboard }, Navigation.newUrl "/leaderboard" )

        ReceiveUserUuid str ->
            let
                uuid =
                    (Uuid.fromString str)
            in
                ( { model | userUuid = uuid }, Cmd.none )

        UrlChange location ->
            handleUrlChange model location

        SetLeaderboard leaderboardMsg ->
            setLeaderboard leaderboardMsg model

        SetPracticePhrases phrasesMsg ->
            setPracticePhrases phrasesMsg model

        Noop ->
            ( model, Cmd.none )


handleUrlChange : ApplicationState -> Navigation.Location -> ( ApplicationState, Cmd Msg )
handleUrlChange model location =
    case location.pathname of
        "/" ->
            ( { model | currentPage = LandingPage }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Moves app into the state of presenting a page for this activity
-}
startActivity : Activity -> ApplicationState -> ( ApplicationState, Cmd Msg )
startActivity activity model =
    case model.userUuid of
        Nothing ->
            ( model, Cmd.none )

        Just userUuid ->
            let
                childModel =
                    PracticePhrases.defaultModel userUuid activity
            in
                ( { model | currentPage = ViewActivity activity childModel }
                , Cmd.batch
                    [ Cmd.map SetPracticePhrases <| PracticePhrases.loadComponent ()
                    , Navigation.newUrl <| urlForActivity activity
                    ]
                )


urlForActivity : Activity -> String
urlForActivity activity =
    case activity of
        FrenchToEnglish ->
            "/practice/french"

        EnglishToFrench ->
            "/practice/english"

        DifferentiateFrenchWords ->
            Debug.crash "Should not have ever been possible to trigger this code"


setPracticePhrases : PracticePhrases.Msg -> ApplicationState -> ( ApplicationState, Cmd Msg )
setPracticePhrases phrasesMsg model =
    case model.currentPage of
        ViewActivity activity practicePhrasesModel ->
            let
                ( practiceModel, msg ) =
                    PracticePhrases.update phrasesMsg practicePhrasesModel
            in
                ( { model | currentPage = ViewActivity activity practiceModel }
                , Cmd.map SetPracticePhrases msg
                )

        _ ->
            -- unfortunately this should be impossible
            ( model, Cmd.none )


setLeaderboard : Leaderboard.Msg -> ApplicationState -> ( ApplicationState, Cmd Msg )
setLeaderboard leaderboardMsg model =
    let
        ( leaderboard, msg ) =
            Leaderboard.update
                leaderboardMsg
                model.leaderboard
    in
        ( { model | leaderboard = leaderboard }, Cmd.map SetLeaderboard msg )


{-| Subscribes to updates from the outside world (ooh, spooky!)
-}
subscriptions : ApplicationState -> Sub Msg
subscriptions model =
    case model.currentPage of
        LandingPage ->
            LocalStorage.getUserUuidResponse ReceiveUserUuid

        ViewLeaderboard ->
            Sub.none

        ViewActivity activity childModel ->
            Sub.map SetPracticePhrases <| PracticePhrases.subscriptions childModel


type alias Flags =
    { seed : Int }


{-| initialize the default model and kick off any initial commands
-}
init : Flags -> Navigation.Location -> ( ApplicationState, Cmd Msg )
init flags location =
    ( defaultModel flags.seed, LocalStorage.getUserUuid () )


main : Program Flags ApplicationState Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
