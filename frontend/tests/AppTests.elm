module AppTests exposing (..)

import App
import Ports.LocalStorage as LocalStorage
import Test exposing (..)
import Expect
import Elmer exposing (atIndex, hasLength, (<&&>))
import Elmer.Html as Markup
import Elmer.Html.Event as Event
import Elmer.Html.Matchers exposing (element, elements, hasText, hasAttribute, hasProperty)
import Elmer.Http
import Elmer.Http.Matchers exposing (..)
import Elmer.Http.Route
import Elmer.Http.Stub
import Elmer.Platform.Subscription as Subscription
import Elmer.Platform.Command as Command
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Elmer.Spy.Matchers exposing (wasCalled, wasCalledWith, stringArg)
import Json.Decode as JD
import Json.Encode as JE
import Phrases exposing (..)
import Task
import Random.Pcg exposing (Seed, initialSeed)
import Uuid exposing (uuidGenerator)
import UuidGenerator


initialViewTests : Test
initialViewTests =
    describe "initial view"
        [ test "it has an option to practice french phrases" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Markup.expect
                        (element <| hasText "French Phrases")
        ]


practiceFrenchPhrasesViewTests : Test
practiceFrenchPhrasesViewTests =
    describe "when practicing french words..."
        [ test "it has a textfield to add a phrase to the list" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
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
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
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
                Elmer.given defaultModel App.view App.update
                    |> Spy.use [ getUserUuidSpy, getItemSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#word-list li"
                    |> Markup.expect
                        (elements <| hasLength 0)
        , test "it doesn't allow duplicates" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "un petit soucis"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "un petit soucis"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Markup.target "#word-list li"
                    |> Markup.expect
                        (elements <| hasLength 1)
        , test "entering a word saves it to local storage" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use [ getUserUuidSpy, getItemSpy, setItemSpy, fakeFocusTaskSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "c'est simple"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Spy.expect "setItem" (wasCalled 1)
        , test "it applies focus to the text input after a word is added" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use [ getUserUuidSpy, getItemSpy, setItemSpy, fakeFocusTaskSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#add-word input"
                    |> Event.input "c'est simple"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Spy.expect "taskFocus"
                        (wasCalled 1)
        ]


renderingPhrasesTests : Test
renderingPhrasesTests =
    describe "when there are phrases in local storage and the backend..."
        [ test "it initially asks for the french phrases it previously saved" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use [ getUserUuidSpy, getItemSpy ]
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Spy.expect "getItem"
                        (wasCalledWith
                            [ stringArg "frenchPhrases" ]
                        )
        , test "it renders the phrases from local storage" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use [ getUserUuidSpy, getItemSpy, getItemResponseSpy ]
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
        , test "it renders the localstorage and backend phrases" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Subscription.send "itemResponseEffect" mockedGetItemResponse
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Markup.target "#word-list li"
                    |> Markup.expect
                        (elements <|
                            (atIndex 0 <| hasText "bonjour")
                                <&&> (atIndex 1 <| hasText "i've got a lovely bunch of coconuts")
                                <&&> (atIndex 2 <| hasText "there they are all standing in a row")
                                <&&> (atIndex 3 <| hasText "big ones, small ones, some as big as your head")
                                <&&> (atIndex 4 <| hasText "give them a twist a flick of the wrist")
                                <&&> (atIndex 5 <| hasText "that's what the showman said")
                        )
        ]


userUuidTests : Test
userUuidTests =
    describe "the user's uuid"
        [ test "will be requested when the app starts" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Spy.expect "getUserUuid" (wasCalled 1)
        , test "the existing uuid will be sent when it does exist" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Subscription.send "userUuidResponseEffect" (Just "941ee33c-725d-45f7-b6a7-908b3d1a2437")
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.get "/api/phrases/french")
                        (Elmer.each <| hasHeader ( "X-User-Token", "941ee33c-725d-45f7-b6a7-908b3d1a2437" ))
        , test "it saves the uuid to local storage" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Subscription.send "userUuidResponseEffect" Nothing
                    |> Spy.expect "setUserUuid"
                        (wasCalledWith
                            [ stringArg uuidForSeed ]
                        )
        , test "a new uuid will be sent when it does not exist a priori" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use allSpies
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Markup.target "#modes button:nth-child(1)"
                    |> Event.click
                    |> Subscription.send "userUuidResponseEffect" Nothing
                    |> Markup.target "#add-word input"
                    |> Event.input "anana qui parle"
                    |> Markup.target "#add-word button"
                    |> Event.click
                    |> Subscription.send "savedToLocalStorageEffect" (JE.string "anana qui parle")
                    |> Elmer.Http.expectThat
                        (Elmer.Http.Route.post "/api/phrases/french")
                        (Elmer.each <|
                            hasHeader ( "X-User-Token", uuidForSeed )
                                <&&> hasBody "{\"content\":\"anana qui parle\"}"
                        )
        ]


defaultModel : App.Model
defaultModel =
    App.defaultModel 0


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
            List.map JE.string longPhrases
    )


longPhrases : List String
longPhrases =
    [ "i've got a lovely bunch of coconuts"
    , "there they are all standing in a row"
    , "big ones, small ones, some as big as your head"
    , "give them a twist a flick of the wrist"
    , "that's what the showman said"
    ]


setUserUuidSpy : Spy
setUserUuidSpy =
    Spy.create "setUserUuid" (\_ -> LocalStorage.setUserUuid)
        |> andCallFake (\_ -> Cmd.none)


getUserUuidSpy : Spy
getUserUuidSpy =
    Spy.create "getUserUuid" (\_ -> LocalStorage.getUserUuid)
        |> andCallFake (\_ -> Cmd.none)


getUserUuidResponseSpy : Spy
getUserUuidResponseSpy =
    Spy.create "getUserUuidResponse" (\_ -> LocalStorage.getUserUuidResponse)
        |> andCallFake
            (\tagger -> Subscription.fake "userUuidResponseEffect" tagger)


savedToLocalStorageSpy : Spy
savedToLocalStorageSpy =
    Spy.create "savedToLocalStorageResponse" (\_ -> LocalStorage.setItemResponse)
        |> andCallFake
            (\tagger -> Subscription.fake "savedToLocalStorageEffect" tagger)


fakeFocusTaskPerform : () -> (() -> msg) -> Task.Task Never () -> Cmd msg
fakeFocusTaskPerform input tagger _ =
    Command.fake (tagger input)


fakeFocusTaskSpy : Spy
fakeFocusTaskSpy =
    Spy.create "taskFocus" (\_ -> Task.perform)
        |> andCallFake (fakeFocusTaskPerform ())


testSeed : Seed
testSeed =
    initialSeed 1


uuidForSeed : String
uuidForSeed =
    "bc178883-a0ee-487b-8059-30db806ed2a9"


nextUuidSpy : Spy
nextUuidSpy =
    Spy.create "uuidGenerator.next" (\_ -> UuidGenerator.next)
        |> andCallFake
            (\_ ->
                Random.Pcg.step uuidGenerator testSeed
            )


allSpies : List Spy
allSpies =
    [ setItemSpy
    , getItemSpy
    , getItemResponseSpy
    , setUserUuidSpy
    , getUserUuidSpy
    , getUserUuidResponseSpy
    , savedToLocalStorageSpy
    , fakeFocusTaskSpy
    , nextUuidSpy
    , httpGetAndPostSpy
    ]


stubbedGetResponse =
    Elmer.Http.Stub.for (Elmer.Http.Route.get "/api/phrases/french")
        |> Elmer.Http.Stub.withBody "[{\"uuid\":\"my-good-uuid\",\"content\":\"bonjour\"}]"


stubbedPostResponse =
    Elmer.Http.Stub.for (Elmer.Http.Route.post "/api/phrases/french")
        |> Elmer.Http.Stub.withBody "{\"uuid\":\"new-uuid\", \"content\":\"bonjour\"}"


httpGetAndPostSpy =
    Elmer.Http.serve [ stubbedGetResponse, stubbedPostResponse ]
