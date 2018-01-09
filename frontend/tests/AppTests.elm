module AppTests
    exposing
        ( landingPageTests
        , leaderboardTests
        , userUuidTests
        )

import App
import Elmer exposing ((<&&>), atIndex)
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Elmer.Html.Matchers exposing (element, elementExists, elements, hasText)
import Elmer.Http
import Elmer.Http.Matchers exposing (hasHeader)
import Elmer.Http.Route
import Elmer.Navigation as ElmerNav
import Elmer.Platform.Subscription as Subscription
import Elmer.Spy as Spy exposing (Spy)
import Elmer.Spy.Matchers exposing (stringArg, wasCalled, wasCalledWith)
import Expect exposing (Expectation)
import Scenarios.Shared exposing (defaultLocation, loggedInUser)
import Scenarios.Shared.Spies exposing (adminErrorCaseSpies, adminSpies, getUserUuidSpy, practiceComponentSpy)
import Test exposing (Test, describe, test)


landingPageTests : Test
landingPageTests =
    describe "the landing page"
        [ test "it has various options for activities to practice" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Markup.target "#Modes button"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "French words and phrases")
                                <&&> (atIndex 1 <| hasText "English words and phrases")
                        )
        , describe "navigating to french practice"
            [ test "shows the practice french page" <|
                \() ->
                    givenIAmPracticingFrench
                        |> Markup.target "div"
                        |> Markup.expect (element <| hasText "Practicing French")
            , test "changes the URL" <|
                \() ->
                    givenIAmPracticingFrench
                        |> ElmerNav.expectLocation "/practice/french"
            , test "prompts the component to load itself" <|
                \() ->
                    givenIAmPracticingFrench
                        |> Spy.expect "practiceComponentLoadSpy" (wasCalled 1)
            ]
        , describe "navigating to english practice"
            [ test "shows the practice english page" <|
                \() ->
                    givenIAmPracticingEnglish
                        |> Markup.target "div"
                        |> Markup.expect (element <| hasText "Practicing English")
            , test "it changes the URL" <|
                \() ->
                    givenIAmPracticingEnglish
                        |> ElmerNav.expectLocation "/practice/english"
            , test "prompts the component to load itself" <|
                \() ->
                    givenIAmPracticingEnglish
                        |> Spy.expect "practiceComponentLoadSpy" (wasCalled 1)
            ]
        ]


userUuidTests : Test
userUuidTests =
    describe "a unique uuid for the user"
        [ test "will be requested when the app starts" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Spy.use [ getUserUuidSpy ]
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Elmer.init (\_ -> App.init { seed = 0 } defaultLocation)
                    |> Spy.expect "getUserUuid" (wasCalled 1)
        ]


leaderboardTests : Test
leaderboardTests =
    describe "the admin portion of the site"
        [ test "has its own URL" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> ElmerNav.expectLocation "/leaderboard"
        , test "it displays a textfield" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Markup.expect elementExists
        , test "it should submit the password to the backend" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "super secret password"
                    |> Markup.target "#AdminSection form button"
                    |> Event.click
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.get "/api/admin")
                        (Elmer.each <| hasHeader ( "X-Password", "super secret password" ))
        , test "it should display the results in a list" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "super secret password"
                    |> Markup.target "#AdminSection form button"
                    |> Event.click
                    |> Markup.target "#AdminSection #Leaderboard"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "the-uuid")
                                <&&> (atIndex 0 <| hasText "11")
                        )
        , test "it should display an error message when the server returns an error" <|
            \() ->
                Elmer.given loggedInUser App.view App.update
                    |> Spy.use adminErrorCaseSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "whoops i accidentally all the things"
                    |> Markup.target "#AdminSection form button"
                    |> Event.click
                    |> Markup.target "#AdminSection #Errors"
                    |> Markup.expect
                        (element <| hasText "Ah ah ah you didn't say the magic word !")
        ]


givenIAmPracticingFrench : Elmer.TestState App.ApplicationState App.Msg
givenIAmPracticingFrench =
    Elmer.given loggedInUser App.view App.update
        |> Spy.use [ practiceComponentSpy, ElmerNav.spy ]
        |> Markup.target "#Modes button"
        |> Event.click


givenIAmPracticingEnglish : Elmer.TestState App.ApplicationState App.Msg
givenIAmPracticingEnglish =
    Elmer.given loggedInUser App.view App.update
        |> Spy.use [ practiceComponentSpy, ElmerNav.spy ]
        |> Markup.target "#Modes #PracticeEnglish"
        |> Event.click
