module AppTests exposing (..)

import Test exposing (..)
import Expect
import Elmer exposing (atIndex, hasLength, (<&&>))
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Elmer.Html.Matchers exposing (element, elements, hasText, hasAttribute, hasProperty)
import Elmer.Platform.Subscription as Subscription
import Elmer.Platform.Command as Command
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Elmer.Spy.Matchers exposing (wasCalled, wasCalledWith, stringArg, anyArg)
import Json.Decode as JD
import Json.Encode as JE
import Task
import App
import Ports.LocalStorage as LocalStorage


initialViewTests : Test
initialViewTests =
    describe "initial view"
        [ test "it has an option to practice french phrases" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Markup.expect
                        (element <| hasText "French Phrases")
        ]


practiceFrenchPhrasesViewTests : Test
practiceFrenchPhrasesViewTests =
    describe "when practicing french words..."
        [ test "it has a textfield to add a phrase to the list" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ setItemSpy, getItemSpy, fakeFocusTaskSpy ]
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "un petit soucis"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "pas de problème"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#word-list li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "un petit soucis")
                                <&&> (atIndex 1 <| hasText "pas de problème")
                        )
        , test "entering a word clears the text input and focuses the input" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ setItemSpy, getItemSpy, fakeFocusTaskSpy ]
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "un petit soucis"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Markup.expect
                        (element <| hasProperty ( "value", "" ))
        , test "adding a blank word is not valid input" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ getItemSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#word-list li"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test "entering a word saves it to local storage" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ getItemSpy, setItemSpy, fakeFocusTaskSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "c'est simple"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Spy.expect "setItem" (wasCalled 1)
        , test "it applies focus to the text input after a word is added" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ getItemSpy, setItemSpy, fakeFocusTaskSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "c'est simple"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Spy.expect "taskFocus"
                        (wasCalled 1)
        ]


renderingFromlocalStorageTests : Test
renderingFromlocalStorageTests =
    describe "when there are saved french phrases in local storage..."
        [ test "it asks for the french phrases it previously saved" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ getItemSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Spy.expect "getItem"
                        (wasCalledWith
                            [ stringArg "frenchPhrases" ]
                        )
        , test "it renders the phrases" <|
            \() ->
                Elmer.given App.defaultModel App.view App.update
                    |> Spy.use [ getItemSpy, getItemResponseSpy ]
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Subscription.send "itemResponseEffect" mockedGetItemResponse
                    |> Markup.target "#word-list li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "i've got a lovely bunch of coconuts")
                                <&&> (atIndex 1 <| hasText "there they are all standing in a row")
                                <&&> (atIndex 2 <| hasText "big ones, small ones, some as big as your head")
                                <&&> (atIndex 3 <| hasText "give them a twist a flick of the wrist")
                                <&&> (atIndex 4 <| hasText "that's what the showman said")
                        )
        ]


setItemSpy : Spy
setItemSpy =
    Spy.create "setItem" (\_ -> LocalStorage.setItem)
        |> andCallFake (\_ -> Cmd.none)


getItemSpy : Spy
getItemSpy =
    Spy.create "getItem" (\_ -> LocalStorage.getItem)
        |> andCallFake (\_ -> Cmd.none)


getItemResponseSpy : Spy
getItemResponseSpy =
    Spy.create "getItemResponse" (\_ -> LocalStorage.getItemResponse)
        |> andCallFake
            (\tagger -> Subscription.fake "itemResponseEffect" tagger)


mockedGetItemResponse : ( String, Maybe JD.Value )
mockedGetItemResponse =
    ( "frenchPhrases"
    , Just <|
        JE.list <|
            List.map JE.string
                [ "i've got a lovely bunch of coconuts"
                , "there they are all standing in a row"
                , "big ones, small ones, some as big as your head"
                , "give them a twist a flick of the wrist"
                , "that's what the showman said"
                ]
    )


fakeFocusTaskPerform : () -> (() -> msg) -> Task.Task Never () -> Cmd msg
fakeFocusTaskPerform input tagger _ =
    Command.fake (tagger input)


fakeFocusTaskSpy : Spy
fakeFocusTaskSpy =
    Spy.create "taskFocus" (\_ -> Task.perform)
        |> andCallFake (fakeFocusTaskPerform ())
