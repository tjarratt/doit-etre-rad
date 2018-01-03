module PracticePhrasesTests
    exposing
        ( addPhraseTests
        , renderingPhrasesTests
        , offlineTests
        , addingTranslationsTests
        )

import Activities exposing (Activity(..))
import Components.PracticePhrases as Component
import Phrases exposing (Phrase(..))
import Elmer exposing ((<&&>), atIndex, hasLength, expectNot)
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Elmer.Html.Matchers exposing (element, elementExists, elements, hasAttribute, hasClass, hasProperty, hasText)
import Elmer.Http
import Elmer.Http.Matchers exposing (hasBody, hasHeader, wasRequested)
import Elmer.Http.Route
import Elmer.Platform.Subscription as Subscription
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Elmer.Spy.Matchers exposing (stringArg, wasCalled, wasCalledWith)
import Json.Encode as JE
import Scenarios exposing (addPhraseToPractice, addTranslation, clickAddPhraseButton, clickPhrase, editPhrase, typePhrase)
import Scenarios.French exposing (allFrenchOfflineSpies, allFrenchSpies)
import Scenarios.Shared.Spies exposing (getItemResponse)
import Test exposing (Test, describe, test)
import Uuid exposing (Uuid)


addPhraseTests : Test
addPhraseTests =
    describe "when practicing phrases"
        [ test "it shows the correct title" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> Markup.target "h1"
                    |> Markup.expect
                        (element <| hasText "Practicing French phrases")
        , test "it has a textfield to add a phrase to the list" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addPhraseToPractice "pas de problème"
                    |> Markup.target "#PhraseList li:nth-child"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "c'est simple")
                                <&&> (atIndex 1 <| hasText "pas de problème")
                        )
        , test "typing in the textfield works as expected" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> typePhrase "c'est simple"
                    |> Markup.target "#add-word input"
                    |> Markup.expect
                        (element <| hasProperty ( "value", "c'est simple" ))
        , test "entering a word clears the text input and focuses the input" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> Markup.target "#add-word input"
                    |> Markup.expect
                        (element <| hasProperty ( "value", "" ))
        , test "adding a blank word is not valid input" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> typePhrase ""
                    |> clickAddPhraseButton
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (expectNot elementExists)
        , test "it doesn't allow duplicates" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addPhraseToPractice "c'est simple"
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <| hasLength 1)
        , test "entering a word saves it to local storage" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> Spy.expect "saveFrenchPhrases" (wasCalled 1)
        , test ", once saved in localstorage, it should save phrases to the backend " <|
            (\() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.post "/api/phrases/french")
                        (wasRequested 1)
            )
        , test "offline tooltips are hidden after the word is saved to the backend" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> Markup.target "#PhraseList li .indexOfflineIndicator"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test "it applies focus to the text input after a word is added" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> Spy.expect "taskFocus"
                        (wasCalled 1)
        ]


renderingPhrasesTests : Test
renderingPhrasesTests =
    describe "when rendering phrases from local storage and the backend"
        [ test "it renders the union of the phrases" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> Subscription.send "getItemResponseEffect" (getItemResponse "frenchPhrases")
                    |> Markup.target "#PhraseList li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "bonjour")
                                -- TODO: not sure I like this feature working this way...
                                -- SHOULD the saved phrases jump to the top of the list ? ...
                                <&&> (atIndex 1 <| hasText "i've got a lovely bunch of coconuts")
                                <&&> (atIndex 2 <| hasText "there they are all standing in a row")
                                <&&> (atIndex 3 <| hasText "big ones, small ones, some as big as your head")
                                <&&> (atIndex 4 <| hasText "give them a twist a flick of the wrist")
                                <&&> (atIndex 5 <| hasText "that's what the showman said")
                        )
        ]


offlineTests : Test
offlineTests =
    describe "when the user is offline"
        [ describe "and they add a phrase"
            [ test "it is rendered with a special icon to indicate it wasn't synced" <|
                \() ->
                    Elmer.given userPracticingFrench Component.view Component.update
                        |> Spy.use allFrenchOfflineSpies
                        |> Subscription.with (\() -> Component.subscriptions)
                        |> addPhraseToPractice "je suis hors-ligne"
                        |> Markup.target "#PhraseList li .indexOfflineIndicator"
                        |> Markup.expect
                            (element <|
                                hasClass "glyphicon-exclamation-sign"
                            )
            , test ", and they add a phrase, the bootstrap tooltips are rendered through a js port" <|
                \() ->
                    Elmer.given userPracticingFrench Component.view Component.update
                        |> Spy.use allFrenchOfflineSpies
                        |> Subscription.with (\() -> Component.subscriptions)
                        |> addPhraseToPractice "je suis hors-ligne"
                        |> Spy.expect "bootstrapTooltips" (wasCalled 1)
            ]
        , describe "and the component loads"
            [ test "existing phrases in local storage get the special icon treatment too" <|
                \() ->
                    Elmer.given userPracticingFrench Component.view Component.update
                        |> Spy.use allFrenchOfflineSpies
                        |> Subscription.with (\() -> Component.subscriptions)
                        |> Subscription.send "getItemResponseEffect" (getItemResponse "frenchPhrases")
                        |> Markup.target "#PhraseList li:first-child .indexOfflineIndicator"
                        |> Markup.expect
                            (element <| hasClass "glyphicon-exclamation-sign")
            , test "the bootstrap port is called to render tooltips" <|
                \() ->
                    Elmer.given userPracticingFrench Component.view Component.update
                        |> Spy.use allFrenchOfflineSpies
                        |> Subscription.with (\() -> Component.subscriptions)
                        |> Subscription.send "getItemResponseEffect" (getItemResponse "frenchPhrases")
                        |> Spy.expect "bootstrapTooltips" (wasCalled 1)
            ]
        ]


addingTranslationsTests : Test
addingTranslationsTests =
    describe "clicking on a phrase"
        [ test "flips the card over" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> clickPhrase
                    |> Markup.target ".indexFlip"
                    |> Markup.expect elementExists
        , test "shows a button to edit the translation" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> clickPhrase
                    |> Markup.target ".indexPhraseListItem .indexAddTranslationButton"
                    |> Markup.expect
                        (element <| hasText "Edit")
        , test ", when edit is clicked, displays an editable textfield" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> clickPhrase
                    |> editPhrase
                    |> Markup.target ".indexPhraseListItem .indexFlip input"
                    |> Markup.expect
                        (elements <| hasLength 1)
        , test ", when edit is clicked, changes the button label to 'Save'" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> clickPhrase
                    |> editPhrase
                    |> Markup.expect
                        (element <| hasText "Save")
        , test ", when the translation is saved, persists the translation to local storage" <|
            \() ->
                Elmer.given userPracticingFrenchWithOnePhrase Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addTranslation "the-uuid" "préexistante" "pre-existing"
                    |> Spy.expect "saveFrenchPhrases" (wasCalled 1)
        , test ", when the translation is saved, the card flips back over" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addTranslation "the-uuid" "c'est simple" "it's simple"
                    |> Subscription.send "getItemResponseEffect" (getItemResponse "frenchPhrases")
                    -- assert no card is flipped
                    |> Markup.target ".indexFlip"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test ", after it saves to local storage, the translation is sent to the backend" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addTranslation "the-uuid" "c'est simple" "it's simple"
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.put <| "/api/phrases/french/the-uuid")
                        (Elmer.each <|
                            hasHeader ( "X-User-Token", defaultUuidString )
                                <&&>
                                    hasBody
                                        (JE.encode 0
                                            (JE.object
                                                [ ( "uuid", JE.string "the-uuid" )
                                                , ( "content", JE.string "c'est simple" )
                                                , ( "translation", JE.string "it's simple" )
                                                ]
                                            )
                                        )
                        )
        , test "the list of phrases is visible again after you translate one" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addPhraseToPractice "pas de problème"
                    |> addTranslation "the-uuid" "c'est simple" "it's simple"
                    |> Markup.target "#PhraseList"
                    |> Markup.expect
                        (element <|
                            hasText "c'est simple"
                                <&&> hasText "pas de problème"
                        )
        , test "it should show the translation if you inspect the card again" <|
            \() ->
                Elmer.given userPracticingFrench Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addTranslation "the-uuid" "c'est simple" "it's simple"
                    |> Subscription.send "getItemResponseEffect" (getItemResponse "frenchPhrases")
                    |> clickPhrase
                    |> Markup.expect (element <| hasText "it's simple")
        , test "it should pre-fill the input when you edit a translation" <|
            \() ->
                Elmer.given userPracticingFrenchWithOnePhrase Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addPhraseToPractice "c'est simple"
                    |> addTranslation "the-uuid" "c'est simple" "it's simple"
                    |> Subscription.send "getItemResponseEffect" (getItemResponse "frenchPhrases")
                    |> clickPhrase
                    |> editPhrase
                    |> Markup.target ".indexPhraseListItem .indexFlip input"
                    |> Markup.expect (element <| hasProperty ( "value", "it's simple" ))
        , test "it should not save the translation if it is empty" <|
            \() ->
                Elmer.given userPracticingFrenchWithOnePhrase Component.view Component.update
                    |> Spy.use allFrenchSpies
                    |> Subscription.with (\() -> Component.subscriptions)
                    |> addTranslation "the-uuid" "préexistante" ""
                    |> Markup.target ".indexPhraseListItem .indexAddTranslationButton"
                    |> Event.click
                    |> Spy.expect "saveFrenchPhrases" (wasCalled 0)
        ]



-- VVV HERE THERE BE DRAGONS VVV --


userPracticingFrench : Component.Model
userPracticingFrench =
    Component.defaultModel defaultUuid FrenchToEnglish


userPracticingFrenchWithOnePhrase : Component.Model
userPracticingFrenchWithOnePhrase =
    { userPracticingFrench
        | phrases = [ { phrase = oneUnsavedPhrase, selected = False, editing = False } ]
    }


oneUnsavedPhrase : Phrases.Phrase
oneUnsavedPhrase =
    Unsaved { content = "préexistante", translation = "" }


defaultUuid : Uuid
defaultUuid =
    case Uuid.fromString defaultUuidString of
        Nothing ->
            Debug.crash "Daaaaang. Uuids are not Uuids."

        Just uuid ->
            uuid


defaultUuidString : String
defaultUuidString =
    "2a09efcb-514d-4ce2-a5db-8fc7edc984fb"
