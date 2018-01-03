module Scenarios
    exposing
        ( practiceFrenchPhrases
        , practiceEnglishPhrases
        , typePhrase
        , clickAddPhraseButton
        , addPhraseToPractice
        , addTranslation
        , clickPhrase
        , editPhrase
        )

import Elmer
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Json.Encode as JE
import Phrases exposing (..)
import Ports.LocalStorage as LocalStorage
import Elmer.Platform.Subscription as Subscription


practiceFrenchPhrases : Elmer.TestState a b -> Elmer.TestState a b
practiceFrenchPhrases testState =
    testState
        |> Markup.target "#Modes #practiceFrench"
        |> Event.click


practiceEnglishPhrases : Elmer.TestState a b -> Elmer.TestState a b
practiceEnglishPhrases testState =
    testState
        |> Markup.target "#Modes #practiceEnglish"
        |> Event.click


addPhraseToPractice : String -> Elmer.TestState a b -> Elmer.TestState a b
addPhraseToPractice phrase testState =
    testState
        |> typePhrase phrase
        |> clickAddPhraseButton
        |> Subscription.send "savedToLocalStorageEffect" (unsavedLocalStorageResponse phrase)


typePhrase : String -> Elmer.TestState a b -> Elmer.TestState a b
typePhrase phrase testState =
    testState
        |> Markup.target "#add-word input"
        |> Event.input phrase


clickAddPhraseButton : Elmer.TestState a b -> Elmer.TestState a b
clickAddPhraseButton testState =
    testState
        |> Markup.target "#add-word button"
        |> Event.click


addTranslation : String -> String -> String -> Elmer.TestState a b -> Elmer.TestState a b
addTranslation uuid phrase translation testState =
    -- adds the given translation to the FIRST phrase in the list
    testState
        |> clickPhrase
        |> editPhrase
        |> typeTranslation translation
        |> saveTranslation
        |> Subscription.send "savedToLocalStorageEffect" (savedLocalStorageResponse uuid phrase translation)


clickPhrase : Elmer.TestState a b -> Elmer.TestState a b
clickPhrase testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexCardContainer"
        |> Event.click


editPhrase : Elmer.TestState a b -> Elmer.TestState a b
editPhrase testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexFlip .indexAddTranslationButton"
        |> Event.click


typeTranslation : String -> Elmer.TestState a b -> Elmer.TestState a b
typeTranslation translation testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexFlip input"
        |> Event.input translation


saveTranslation : Elmer.TestState a b -> Elmer.TestState a b
saveTranslation testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexFlip .indexAddTranslationButton"
        |> Event.click


unsavedLocalStorageResponse : String -> JE.Value
unsavedLocalStorageResponse phrase =
    LocalStorage.phraseEncoder <|
        Unsaved { content = phrase, translation = "" }


savedLocalStorageResponse : String -> String -> String -> JE.Value
savedLocalStorageResponse uuid phrase translation =
    LocalStorage.phraseEncoder <|
        Saved { uuid = uuid, content = phrase, translation = translation }
