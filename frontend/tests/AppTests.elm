module AppTests exposing (..)

import App
import Test exposing (..)
import Elmer exposing (atIndex, hasLength, (<&&>))
import Elmer.Html.Event as Event
import Elmer.Html as Markup
import Elmer.Html.Matchers exposing (element, elements, elementExists, hasClass, hasText, hasAttribute, hasProperty)
import Elmer.Http
import Elmer.Http.Matchers exposing (hasHeader)
import Elmer.Http.Route
import Elmer.Spy as Spy
import Elmer.Platform.Subscription as Subscription
import Scenarios exposing (..)
import Scenarios.French exposing (..)
import Scenarios.English exposing (..)
import Scenarios.Shared exposing (..)
import Scenarios.Shared.Spies exposing (adminSpies, adminErrorCaseSpies)
import Scenarios.TestSetup exposing (TestSetup)


initialViewTests : Test
initialViewTests =
    describe "initial view"
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


practiceFrenchPhrasesViewTests : Test
practiceFrenchPhrasesViewTests =
    practiceActivityTests frenchSetup


practiceEnglishPhrasesViewTests : Test
practiceEnglishPhrasesViewTests =
    practiceActivityTests englishSetup


renderingFrenchPhrasesTests : Test
renderingFrenchPhrasesTests =
    renderingPhrasesTests frenchSetup


renderingEnglishPhrasesTests : Test
renderingEnglishPhrasesTests =
    renderingPhrasesTests englishSetup


addingFrenchTranslationsTests : Test
addingFrenchTranslationsTests =
    addingTranslationsTests frenchSetup


addingEnglishTranslationsTests : Test
addingEnglishTranslationsTests =
    addingTranslationsTests englishSetup


frenchOfflineTests : Test
frenchOfflineTests =
    offlineTests { frenchSetup | allSpies = allFrenchOfflineSpies }


englishOfflineTests : Test
englishOfflineTests =
    offlineTests { englishSetup | allSpies = allEnglishOfflineSpies }


frenchUserUuidTests : Test
frenchUserUuidTests =
    userUuidTests frenchSetup


englishUserUuidTests : Test
englishUserUuidTests =
    userUuidTests englishSetup


leaderboardTests : Test
leaderboardTests =
    describe "the admin portion of the site"
        [ test "it displays a textfield" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Markup.expect elementExists
        , test "it should submit the password to the backend" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton"
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
                    |> Markup.target "#SecretButton"
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
        , test "it should display an error message when the request fails" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use adminErrorCaseSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#SecretButton"
                    |> Event.click
                    |> Markup.target "#AdminSection #PasswordField"
                    |> Event.input "whoops i accidentally all the things"
                    |> Markup.target "#AdminSection button"
                    |> Event.click
                    |> Markup.target "#AdminSection #Errors"
                    |> Markup.expect
                        (element <| hasText "ah ah ah you didn't say the magic word")
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
    , allSpies = allFrenchSpies
    , inputPhrase1 = "c'est simple"
    , inputTranslation1 = "it's simple"
    , inputPhrase2 = "pas de problème"
    , savedPhrase = "bonjour"
    , getItemSpyName = "frenchPhrases"
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
    , allSpies = allEnglishSpies
    , inputPhrase1 = "it's simple"
    , inputTranslation1 = "c'est simple"
    , inputPhrase2 = "no problem"
    , savedPhrase = "hello"
    , getItemSpyName = "englishPhrases"
    }
