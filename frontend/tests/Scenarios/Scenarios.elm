module Scenarios
    exposing
        ( practiceFrenchPhrases
        , practiceEnglishPhrases
        , addPhraseToPractice
        , addTranslation
        , clickPhrase
        , editPhrase
        , typeTranslation
        , saveTranslation
        )

import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Json.Encode as JE
import Phrases exposing (..)
import Ports.LocalStorage as LocalStorage
import Elmer.Platform.Subscription as Subscription


practiceFrenchPhrases testState =
    testState
        |> Markup.target "#Modes #practiceFrench"
        |> Event.click


practiceEnglishPhrases testState =
    testState
        |> Markup.target "#Modes #practiceEnglish"
        |> Event.click


addPhraseToPractice phrase testState =
    testState
        |> Markup.target "#add-word input"
        |> Event.input phrase
        |> Markup.target "#add-word button"
        |> Event.click
        |> Subscription.send "savedToLocalStorageEffect" (unsavedLocalStorageResponse phrase)


addTranslation uuid phrase translation testState =
    -- adds the given translation to the FIRST phrase in the list
    testState
        |> clickPhrase
        |> editPhrase
        |> typeTranslation translation
        |> saveTranslation
        |> Subscription.send "savedToLocalStorageEffect" (savedLocalStorageResponse uuid phrase translation)


clickPhrase testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexCardContainer"
        |> Event.click


editPhrase testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexFlip .indexAddTranslationButton"
        |> Event.click


typeTranslation translation testState =
    testState
        |> Markup.target ".indexPhraseListItem .indexFlip input"
        |> Event.input translation


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
