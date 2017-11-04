module Scenarios.Shared.Spies exposing (..)

import Phrases exposing (..)
import Ports.Bootstrap as Bootstrap
import Ports.LocalStorage as LocalStorage
import Json.Decode as JD
import Json.Encode as JE
import Random.Pcg exposing (Seed, initialSeed)
import Task
import Uuid exposing (uuidGenerator)
import UuidGenerator
import Elmer.Platform.Command as Command
import Elmer.Platform.Subscription as Subscription
import Elmer.Http
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Scenarios.Shared.Http exposing (..)


sharedSpies : List Spy
sharedSpies =
    [ getItemSpy
    , getItemResponseSpy
    , setUserUuidSpy
    , getUserUuidSpy
    , getUserUuidResponseSpy
    , savedToLocalStorageSpy
    , fakeFocusTaskSpy
    , showTooltipSpy
    , nextUuidSpy
    ]


allOfflineSpies : String -> String -> String -> List Spy
allOfflineSpies endpoint phrase1 phrase2 =
    (offlineSpies endpoint phrase1 phrase2) :: sharedSpies


allHttpSpies : String -> String -> String -> List Spy
allHttpSpies endpoint newPhrase savedPhrase =
    Elmer.Http.serve
        [ stubbedGetResponse endpoint savedPhrase
        , stubbedPostResponse endpoint newPhrase
        ]
        :: sharedSpies



{-
   Spies for Ports
-}


getItemSpy : Spy
getItemSpy =
    Spy.create "getItem" (\_ -> LocalStorage.getItem)
        |> andCallFake (\_ -> Cmd.none)


getItemResponseSpy : Spy
getItemResponseSpy =
    Spy.create "getItemResponse" (\_ -> LocalStorage.getItemResponse)
        |> andCallFake
            (\tagger -> Subscription.fake "itemResponseEffect" tagger)


getItemResponse : String -> ( String, Maybe JD.Value )
getItemResponse localStorageKey =
    ( localStorageKey
    , Just <|
        JE.list <|
            List.map LocalStorage.phraseEncoder longPhrases
    )


longPhrases : List Phrase
longPhrases =
    [ Unsaved "i've got a lovely bunch of coconuts"
    , Unsaved "there they are all standing in a row"
    , Unsaved "big ones, small ones, some as big as your head"
    , Unsaved "give them a twist a flick of the wrist"
    , Unsaved "that's what the showman said"
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



{-
   Spies for UI concerns
-}


fakeFocusTaskPerform : () -> (() -> msg) -> Task.Task Never () -> Cmd msg
fakeFocusTaskPerform input tagger _ =
    Command.fake (tagger input)


fakeFocusTaskSpy : Spy
fakeFocusTaskSpy =
    Spy.create "taskFocus" (\_ -> Task.perform)
        |> andCallFake (fakeFocusTaskPerform ())


showTooltipSpy : Spy
showTooltipSpy =
    Spy.create "bootstrapTooltips" (\_ -> Bootstrap.showTooltips)
        |> andCallFake (\_ -> Cmd.none)



{-
   Spies for UUIDs
-}


cannedSeed : Seed
cannedSeed =
    initialSeed 1


uuidForSeed : String
uuidForSeed =
    "bc178883-a0ee-487b-8059-30db806ed2a9"


nextUuidSpy : Spy
nextUuidSpy =
    Spy.create "uuidGenerator.next" (\_ -> UuidGenerator.next)
        |> andCallFake
            (\_ ->
                Random.Pcg.step uuidGenerator cannedSeed
            )
