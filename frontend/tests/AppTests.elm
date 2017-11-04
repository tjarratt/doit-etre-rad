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



-- TODO write a similar test for english


practiceFrenchPhrasesViewTests : Test
practiceFrenchPhrasesViewTests =
    practiceActivityTests frenchSetup



-- TODO write a similar test for english


renderingFrenchPhrasesTests : Test
renderingFrenchPhrasesTests =
    renderingPhrasesTests frenchSetup



-- TODO : write a similar test for english


frenchOfflineTests : Test
frenchOfflineTests =
    offlineTests { frenchSetup | allSpies = allFrenchOfflineSpies }



-- TODO: write an english version of this


frenchUserUuidTests : Test
frenchUserUuidTests =
    userUuidTests frenchSetup


frenchSetup =
    { language = "french"
    , startActivityScenario = practiceFrenchPhrases
    , localStorageSpyName = "saveFrenchPhrases"
    , expectedEndpoint = "/api/phrases/french"
    , allSpies = allFrenchSpies
    , inputPhrase1 = "c'est simple"
    , inputPhrase2 = "pas de problème"
    , savedPhrase = "bonjour"
    , getItemSpyName = "frenchPhrases"
    }


englishSetup =
    { language = "english"
    , startActivityScenario = practiceEnglishPhrases
    , localStorageSpyName = "saveEnglishPhrases"
    , expectedEndpoint = "/api/phrases/english"
    , allSpies = allEnglishSpies
    , inputPhrase1 = "it's simple"
    , inputPhrase2 = "no problem"
    , savedPhrase = "hello"
    , getItemSpyName = "englishPhrases"
    }
