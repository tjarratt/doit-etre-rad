module Scenarios
    exposing
        ( practiceFrenchPhrases
        , practiceEnglishPhrases
        , addPhraseToPractice
        , addTranslation
        )

import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Json.Decode as JD
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
        |> Subscription.send "savedToLocalStorageEffect" mockedSaveItemResponse


addTranslation translation testState =
    -- adds the given translation to the FIRST phrase in the list
    testState
        -- show the backside of the card
        |> Markup.target ".indexPhraseListItem .indexCardContainer"
        |> Event.click
        -- make the input editable
        |> Markup.target ".indexPhraseListItem .indexFlip .indexAddTranslationButton"
        |> Event.click
        -- input the translation desired
        |> Markup.target ".indexPhraseListItem .indexFlip input"
        |> Event.input translation
        -- save the translation
        |> Markup.target ".indexPhraseListItem .indexFlip .indexAddTranslationButton"
        |> Event.click


mockedSaveItemResponse : String -> JD.Value
mockedSaveItemResponse phrase =
    LocalStorage.phraseEncoder <|
        Unsaved { content = phrase, translation = "" }
