module Scenarios.English
    exposing
        ( allEnglishSpies
        , allEnglishOfflineSpies
        , saveEnglishPhrasesSpy
        )

import Ports.LocalStorage
import Scenarios.Shared exposing (..)
import Scenarios.Shared.Spies exposing (..)
import Elmer.Spy


allEnglishSpies : List Elmer.Spy.Spy
allEnglishSpies =
    saveEnglishPhrasesSpy :: (withEnglishSettings allHttpSpies)


allEnglishOfflineSpies : List Elmer.Spy.Spy
allEnglishOfflineSpies =
    saveEnglishPhrasesSpy :: (withEnglishSettings allOfflineSpies)


saveEnglishPhrasesSpy : Elmer.Spy.Spy
saveEnglishPhrasesSpy =
    Elmer.Spy.create "saveEnglishPhrases" (\_ -> Ports.LocalStorage.saveEnglishPhrases)
        |> Elmer.Spy.andCallFake (\_ -> Cmd.none)


withEnglishSettings : (String -> String -> String -> List Elmer.Spy.Spy) -> List Elmer.Spy.Spy
withEnglishSettings spyProducer =
    spyProducer "/api/phrases/english" "it's simple" "hello"
