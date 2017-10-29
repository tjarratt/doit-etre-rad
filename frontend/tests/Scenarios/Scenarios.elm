module Scenarios exposing (..)

import Elmer.Html as Markup
import Elmer.Html.Event as Event


practiceFrenchPhrases testState =
    testState
        |> Markup.target "#Modes button:nth-child(1)"
        |> Event.click


addPhraseToPractice phrase testState =
    testState
        |> Markup.target "#add-word input"
        |> Event.input phrase
        |> Markup.target "#add-word button"
        |> Event.click
