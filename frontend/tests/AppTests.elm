module AppTests exposing (..)

import App
import Test exposing (..)
import Elmer exposing (atIndex, hasLength, (<&&>))
import Elmer.Html as Markup
import Elmer.Html.Matchers exposing (element, elements, hasClass, hasText, hasAttribute, hasProperty)
import Elmer.Http
import Elmer.Http.Matchers exposing (..)
import Elmer.Http.Route
import Elmer.Http.Stub
import Elmer.Platform.Subscription as Subscription
import Elmer.Spy as Spy
import Elmer.Spy.Matchers exposing (wasCalled, wasCalledWith, stringArg)
import Scenarios exposing (..)
import Scenarios.French exposing (..)
import Scenarios.English exposing (..)
import Scenarios.Shared exposing (..)


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


frenchSetup =
    { language = "french"
    , expectedTitle = "Practicing French phrases"
    , startActivityScenario = practiceFrenchPhrases
    , localStorageSpyName = "saveFrenchPhrases"
    , expectedEndpoint = "/api/phrases/french"
    , allSpies = allFrenchSpies
    , inputPhrase1 = "c'est simple"
    , inputTranslation1 = "it's simple"
    , inputPhrase2 = "pas de problème"
    , savedPhrase = "bonjour"
    , getItemSpyName = "frenchPhrases"
    }


englishSetup =
    { language = "english"
    , expectedTitle = "Practicing English phrases"
    , startActivityScenario = practiceEnglishPhrases
    , localStorageSpyName = "saveEnglishPhrases"
    , expectedEndpoint = "/api/phrases/english"
    , allSpies = allEnglishSpies
    , inputPhrase1 = "it's simple"
    , inputTranslation1 = "c'est simple"
    , inputPhrase2 = "no problem"
    , savedPhrase = "hello"
    , getItemSpyName = "englishPhrases"
    }
