module Scenarios.French
    exposing
        ( allFrenchSpies
        , allFrenchOfflineSpies
        , saveFrenchPhrasesSpy
        )

import Ports.LocalStorage
import Scenarios.Shared.Spies exposing (..)
import Elmer.Spy


allFrenchSpies : List Elmer.Spy.Spy
allFrenchSpies =
    saveFrenchPhrasesSpy :: (withFrenchSettings allHttpSpies)


allFrenchOfflineSpies : List Elmer.Spy.Spy
allFrenchOfflineSpies =
    saveFrenchPhrasesSpy :: (withFrenchSettings allOfflineSpies)


saveFrenchPhrasesSpy : Elmer.Spy.Spy
saveFrenchPhrasesSpy =
    Elmer.Spy.create "saveFrenchPhrases" (\_ -> Ports.LocalStorage.saveFrenchPhrases)
        |> Elmer.Spy.andCallFake (\_ -> Cmd.none)


withFrenchSettings : (String -> String -> String -> List Elmer.Spy.Spy) -> List Elmer.Spy.Spy
withFrenchSettings spyProducer =
    spyProducer "/api/phrases/french" "c'est simple" "bonjour"
