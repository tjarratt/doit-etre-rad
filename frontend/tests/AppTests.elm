module AppTests
    exposing
        ( landingPageTests
        , practiceFrenchTests
        , practiceEnglishTests
        , leaderboardTests
        , userUuidTests
        )

import App
import Activities
import Test exposing (Test, describe, test)
import Elmer exposing (atIndex, (<&&>))
import Elmer.Html.Event as Event
import Elmer.Html as Markup
import Elmer.Html.Matchers exposing (element, elements, elementExists, hasText)
import Elmer.Http
import Elmer.Http.Matchers exposing (hasHeader)
import Elmer.Http.Route
import Elmer.Spy as Spy
import Elmer.Spy.Matchers exposing (wasCalled)
import Elmer.Platform.Subscription as Subscription
import Scenarios exposing (practiceFrenchPhrases, practiceEnglishPhrases)
import Scenarios.Shared
    exposing
        ( practiceActivityTests
        , defaultModel
        )
import Scenarios.Shared.Spies
    exposing
        ( adminSpies
        , adminErrorCaseSpies
        , getUserUuidSpy
        )
import Scenarios.TestSetup exposing (TestSetup)


landingPageTests : Test
landingPageTests =
    describe "the landing page"
        [ test "it has various options for activities to practice" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Markup.target "#Modes button"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "French words and phrases")
                                <&&> (atIndex 1 <| hasText "English words and phrases")
                        )
        ]


userUuidTests : Test
userUuidTests =
    describe "a unique uuid for the user"
        [ test "will be requested when the app starts" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use [ getUserUuidSpy ]
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Elmer.init (\_ -> App.init { seed = 0 })
                    |> Spy.expect "getUserUuid" (wasCalled 1)
        ]


practiceFrenchTests : Test
practiceFrenchTests =
    practiceActivityTests frenchSetup


practiceEnglishTests : Test
practiceEnglishTests =
    practiceActivityTests englishSetup


leaderboardTests : Test
leaderboardTests =
    describe "the admin portion of the site"
        [ test "it displays a textfield" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Markup.expect elementExists
        , test "it should submit the password to the backend" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "super secret password"
                    |> Markup.target "#AdminSection button"
                    |> Event.click
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.get "/api/admin")
                        (Elmer.each <| hasHeader ( "X-Password", "super secret password" ))
        , test "it should display the results in a list" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "super secret password"
                    |> Markup.target "#AdminSection button"
                    |> Event.click
                    |> Markup.target "#AdminSection #Leaderboard"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "the-uuid")
                                <&&> (atIndex 0 <| hasText "11")
                        )
        , test "it should display an error message when the server returns an error" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminErrorCaseSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton button"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "whoops i accidentally all the things"
                    |> Markup.target "#AdminSection button"
                    |> Event.click
                    |> Markup.target "#AdminSection #Errors"
                    |> Markup.expect
                        (element <| hasText "Ah ah ah you didn't say the magic word !")
        ]


frenchSetup : TestSetup
frenchSetup =
    { language = "french"
    , expectedTitle = "Practicing French phrases"
    , startActivityScenario = practiceFrenchPhrases
    , localStorageSpyName = "saveFrenchPhrases"
    , readEndpoint = "/api/phrases/french"
    , createEndpoint = "/api/phrases/french"
    , updateEndpoint = \str -> "/api/phrases/french/" ++ str
    , inputPhrase1 = "c'est simple"
    , inputTranslation1 = "it's simple"
    , inputPhrase2 = "pas de problème"
    , savedPhrase = "bonjour"
    , getItemSpyName = "frenchPhrases"
    , activity = Activities.FrenchToEnglish
    }


englishSetup : TestSetup
englishSetup =
    { language = "english"
    , expectedTitle = "Practicing English phrases"
    , startActivityScenario = practiceEnglishPhrases
    , localStorageSpyName = "saveEnglishPhrases"
    , readEndpoint = "/api/phrases/english"
    , createEndpoint = "/api/phrases/english"
    , updateEndpoint = \str -> "/api/phrases/english/" ++ str
    , inputPhrase1 = "it's simple"
    , inputTranslation1 = "c'est simple"
    , inputPhrase2 = "no problem"
    , savedPhrase = "hello"
    , getItemSpyName = "englishPhrases"
    , activity = Activities.EnglishToFrench
    }
