module Scenarios.Shared.Spies
    exposing
        ( allOfflineSpies
        , allOnlineSpies
        , adminSpies
        , adminErrorCaseSpies
        , getItemSpy
        , getItemResponse
        , getUserUuidSpy
        , getUserUuidResponseSpy
        , taskSpy
        , practiceComponentSpy
        , navigationBackSpy
        )

import Components.PracticePhrases as PracticePhrases
import Phrases exposing (..)
import Ports.Bootstrap as Bootstrap
import Ports.LocalStorage as LocalStorage
import Json.Decode as JD
import Json.Encode as JE
import Navigation
import Task
import Urls
import Elmer.Navigation as ElmerNav
import Elmer.Platform.Command as Command
import Elmer.Platform.Subscription as Subscription
import Elmer.Http
import Elmer.Http.Route
import Elmer.Http.Status exposing (unauthorized)
import Elmer.Http.Stub
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Scenarios.Shared.Http
    exposing
        ( offlineSpies
        , stubbedGetResponse
        , stubbedPutResponse
        , stubbedPostResponse
        )


sharedSpies : List Spy
sharedSpies =
    [ getItemSpy
    , getItemResponseSpy
    , getUserUuidSpy
    , getUserUuidResponseSpy
    , savedToLocalStorageSpy
    , taskSpy
    , showTooltipSpy
    ]


allOfflineSpies : String -> ( String, String, String ) -> String -> List Spy
allOfflineSpies endpoint ( _, phrase1, _ ) phrase2 =
    (offlineSpies endpoint phrase1 phrase2) :: sharedSpies


allOnlineSpies : String -> ( String, String, String ) -> String -> List Spy
allOnlineSpies endpoint ( uuid, newPhrase, translation ) savedPhrase =
    Elmer.Http.serve
        [ stubbedGetResponse endpoint savedPhrase
        , stubbedPostResponse endpoint newPhrase
        , stubbedPutResponse endpoint ( uuid, newPhrase, translation )
        ]
        :: sharedSpies


adminSpies : List Spy
adminSpies =
    [ Elmer.Http.serve
        [ Elmer.Http.Stub.for (Elmer.Http.Route.get Urls.adminApiUrl)
            |> Elmer.Http.Stub.withBody """[{"userUuid": "the-uuid", "phraseCount": 11}]"""
        ]
    , ElmerNav.spy
    ]


adminErrorCaseSpies : List Spy
adminErrorCaseSpies =
    [ Elmer.Http.serve
        [ Elmer.Http.Stub.for (Elmer.Http.Route.get Urls.adminApiUrl)
            |> Elmer.Http.Stub.withBody """{"error": "Ah ah ah you didn't say the magic word !"}"""
            |> Elmer.Http.Stub.withStatus unauthorized
        ]
    , ElmerNav.spy
    ]



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
            (\tagger -> Subscription.fake "getItemResponseEffect" tagger)


getItemResponse : String -> ( String, Maybe JD.Value )
getItemResponse localStorageKey =
    ( localStorageKey
    , Just <|
        JE.list <|
            List.map LocalStorage.phraseEncoder longPhrases
    )


longPhrases : List Phrase
longPhrases =
    [ Unsaved { content = "i've got a lovely bunch of coconuts", translation = "" }
    , Unsaved { content = "there they are all standing in a row", translation = "" }
    , Unsaved { content = "big ones, small ones, some as big as your head", translation = "" }
    , Unsaved { content = "give them a twist a flick of the wrist", translation = "" }
    , Unsaved { content = "that's what the showman said", translation = "" }
    ]


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
   Spies for navigation
-}


navigationBackSpy : Spy
navigationBackSpy =
    Spy.create "Navigation.back" (\_ -> Navigation.back)
        |> andCallFake (\_ -> Cmd.none)



{-
   Spies for UI concerns
-}


fakeFocusTaskPerform : () -> (() -> msg) -> Task.Task Never () -> Cmd msg
fakeFocusTaskPerform input tagger _ =
    Command.fake (tagger input)


taskSpy : Spy
taskSpy =
    Spy.create "taskFocus" (\_ -> Task.perform)
        |> andCallFake (fakeFocusTaskPerform ())


showTooltipSpy : Spy
showTooltipSpy =
    Spy.create "bootstrapTooltips" (\_ -> Bootstrap.showTooltips)
        |> andCallFake (\_ -> Cmd.none)



{-
   Spies for Components
-}


practiceComponentSpy : Spy
practiceComponentSpy =
    Spy.create "practiceComponentLoadSpy" (\_ -> PracticePhrases.loadComponent)
        |> andCallFake (\_ -> Cmd.none)
