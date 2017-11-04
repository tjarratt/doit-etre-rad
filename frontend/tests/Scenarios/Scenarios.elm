module Scenarios
    exposing
        ( practiceFrenchPhrases
        , practiceEnglishPhrases
        , addPhraseToPractice
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


mockedSaveItemResponse : String -> JD.Value
mockedSaveItemResponse phrase =
    LocalStorage.phraseEncoder <| Unsaved phrase
