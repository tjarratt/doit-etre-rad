module AppTests exposing (..)

import Test exposing (..)
import Expect
import Elmer exposing (atIndex, (<&&>))
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Elmer.Html.Matchers exposing (element, elements, hasText, hasAttribute, hasProperty)
import App


initialViewTests : Test
initialViewTests =
    describe "initial view"
        [ test "it has an option to practice french phrases" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "French Phrases")
                        )
        ]


practiceFrenchPhrasesViewTests : Test
practiceFrenchPhrasesViewTests =
    describe "when practicing french words..."
        [ test "it has a textfield to add a phrase to the list" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "une petite soucis"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#word-list li:nth-child(1)"
                    |> Markup.expect
                        (element <| hasText "une petite soucis")
        , test "entering a word clears the text input" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "une petite soucis"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Markup.expect
                        (element <| hasProperty ( "value", "" ))
        ]
