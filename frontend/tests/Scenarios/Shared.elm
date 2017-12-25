module Scenarios.Shared exposing (..)

import App
import Phrases exposing (..)
import Ports.LocalStorage as LocalStorage
import Elmer exposing (atIndex, hasLength, (<&&>))
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Elmer.Html.Matchers exposing (element, elements, hasClass, hasText, hasAttribute, hasProperty)
import Elmer.Http
import Elmer.Http.Matchers exposing (..)
import Elmer.Http.Route
import Elmer.Http.Stub
import Elmer.Platform.Subscription as Subscription
import Elmer.Platform.Command as Command
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Elmer.Spy.Matchers exposing (wasCalled, wasCalledWith, stringArg)
import Expect
import Json.Decode as JD
import Json.Encode as JE
import Scenarios exposing (..)
import Scenarios.Shared.Http exposing (..)
import Scenarios.Shared.Spies exposing (..)
import Test exposing (..)


defaultModel : App.Model
defaultModel =
    App.defaultModel 0


exactlyOnePhraseSaved : App.Model
exactlyOnePhraseSaved =
    { defaultModel
        | phrases =
            [ { phrase = Saved { uuid = "the-uuid", content = "bonjour", translation = "" }
              , selected = False
              , editing = False
              }
            ]
    }


type alias ScenarioSetup a b =
    { language : String
    , expectedTitle : String
    , startActivityScenario : a -> b
    , localStorageSpyName : String
    , getItemSpyName : String
    , expectedEndpoint : String
    , allSpies : List Spy
    , inputPhrase1 : String
    , inputPhrase2 : String
    , savedPhrase : String
    }


practiceActivityTests setup =
    describe ("when practicing " ++ setup.language ++ " phrases...")
        [ test "it shows the correct title" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Markup.target "h1"
                    |> Markup.expect
                        (element <| hasText setup.expectedTitle)
        , test "it has a textfield to add a phrase to the list" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> addPhraseToPractice setup.inputPhrase2
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText setup.inputPhrase1)
                                <&&> (atIndex 1 <| hasText setup.inputPhrase2)
                        )
        , test "entering a word clears the text input and focuses the input" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Markup.target "#add-word input"
                    |> Markup.expect
                        (element <| hasProperty ( "value", "" ))
        , test "adding a blank word is not valid input" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice ""
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test "it doesn't allow duplicates" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <| hasLength 1)
        , test "entering a word saves it to local storage" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Spy.expect setup.localStorageSpyName (wasCalled 1)
        , test "entering a word saves it to the backend as well" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.post setup.expectedEndpoint)
                        (wasRequested 1)
        , test "offline tooltips are hidden after the word is saved to the backend" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Markup.target "#PhraseList li .indexOfflineIndicator"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test "it applies focus to the text input after a word is added" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Spy.expect "taskFocus"
                        (wasCalled 1)
        , test "items that are only saved in local storage have tooltips" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Spy.expect "bootstrapTooltips"
                        (wasCalled 1)
        ]


addingTranslationsTests setup =
    describe
        ("clicking on a " ++ setup.language ++ " phrase")
        [ test "it should display a textfield to add a translation" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Markup.target ".indexPhraseListItem .indexCardContainer"
                    |> Event.click
                    |> Markup.target ".indexPhraseListItem .indexAddPhraseTranslation"
                    |> Markup.expect
                        (elements <| hasLength 1)
        , test "it should have a button to edit the translation" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Markup.target ".indexPhraseListItem .indexCardContainer"
                    |> Event.click
                    |> Markup.target ".indexPhraseListItem .indexAddTranslationButton"
                    |> Markup.expect
                        (element <| hasText "Edit")
        , test "it should change the edit button to save when it is clicked" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice setup.inputPhrase1
                    |> Markup.target ".indexPhraseListItem .indexCardContainer"
                    |> Event.click
                    |> Markup.target ".indexPhraseListItem .indexFlip .indexAddTranslationButton"
                    |> Event.click
                    |> Markup.expect
                        (element <| hasText "Save")
        , test "it should save the translation to local storage" <|
            \() ->
                Elmer.given exactlyOnePhraseSaved App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addTranslation setup.inputTranslation1
                    |> Spy.expect setup.localStorageSpyName (wasCalled 1)
        , test "it should flip the card back over" <|
            \() ->
                Elmer.given exactlyOnePhraseSaved App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addTranslation setup.inputTranslation1
                    -- trigger local storage response
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    -- assert no card is flipped
                    |> Markup.target ".indexFlip"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test "it should not save the translation if it is empty" <|
            \() ->
                Elmer.given exactlyOnePhraseSaved App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addTranslation ""
                    |> Markup.target ".indexPhraseListItem .indexAddTranslationButton"
                    |> Event.click
                    |> Spy.expect setup.localStorageSpyName (wasCalled 0)
        ]


renderingPhrasesTests setup =
    describe
        ("when there are " ++ setup.language ++ " phrases in local storage and the backend...")
        [ test "it initially queries local storage for the phrases it previously saved" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Spy.expect "getItem"
                        (wasCalledWith
                            [ stringArg setup.getItemSpyName ]
                        )
        , test "it renders the phrases from local storage" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "i've got a lovely bunch of coconuts")
                                <&&> (atIndex 1 <| hasText "there they are all standing in a row")
                                <&&> (atIndex 2 <| hasText "big ones, small ones, some as big as your head")
                                <&&> (atIndex 3 <| hasText "give them a twist a flick of the wrist")
                                <&&> (atIndex 4 <| hasText "that's what the showman said")
                        )
        , test "it renders the localstorage and backend phrases" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText setup.savedPhrase)
                                <&&> (atIndex 1 <| hasText "i've got a lovely bunch of coconuts")
                                <&&> (atIndex 2 <| hasText "there they are all standing in a row")
                                <&&> (atIndex 3 <| hasText "big ones, small ones, some as big as your head")
                                <&&> (atIndex 4 <| hasText "give them a twist a flick of the wrist")
                                <&&> (atIndex 5 <| hasText "that's what the showman said")
                        )
        ]


offlineTests setup =
    describe ("when the user is offline and adds " ++ setup.language ++ " phrases")
        [ test "they will be rendered with a special icon to indicate it wasn't synced" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> addPhraseToPractice "whoops"
                    |> addPhraseToPractice "hors ligne"
                    |> Markup.target "#PhraseList li .indexOfflineIndicator"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasClass "glyphicon-exclamation-sign")
                                <&&> (atIndex 1 <| hasClass "glyphicon-exclamation-sign")
                        )
        , test "they are rendered with offline-explanation tooltips" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    |> addPhraseToPractice "hors ligne"
                    |> Spy.expect "bootstrapTooltips"
                        (wasCalled 3)
        , test "existing phrases in local storage get the special icon treatment too" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    |> Markup.target "#PhraseList li:first-child .indexOfflineIndicator"
                    |> Markup.expect
                        (element <| hasClass "glyphicon-exclamation-sign")
        , test "existing phrases in local storage get the offline tooltips treatment as well" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Subscription.send "itemResponseEffect" (getItemResponse setup.getItemSpyName)
                    |> Spy.expect "bootstrapTooltips"
                        (wasCalled 2)
        ]


userUuidTests setup =
    describe ("keeping track of " ++ setup.language ++ " phrases by user uuid")
        [ test "will be requested when the app starts" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Spy.expect "getUserUuid" (wasCalled 1)
        , test "the existing uuid will be sent when it does exist" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.get setup.expectedEndpoint)
                        (Elmer.each <| hasHeader ( "X-User-Token", "941ee33c-725d-45f7-b6a7-908b3d1a2437" ))
        , test "it saves the uuid to local storage" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" Nothing
                    |> Spy.expect "setUserUuid"
                        (wasCalledWith
                            [ stringArg uuidForSeed ]
                        )
        , test "a new uuid will be sent when it does not exist a priori" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use setup.allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> setup.startActivityScenario
                    |> Subscription.send "userUuidResponseEffect" Nothing
                    |> Subscription.send "savedToLocalStorageEffect" (JE.string "anana qui parle")
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.post setup.expectedEndpoint)
                        (Elmer.each <|
                            hasHeader ( "X-User-Token", uuidForSeed )
                                <&&> hasBody "{\"content\":\"anana qui parle\"}"
                        )
        ]
