module Scenarios.French exposing (allFrenchSpies, allFrenchOfflineSpies)

import Ports.LocalStorage
import Scenarios.Shared.Spies exposing (allOnlineSpies, allOfflineSpies)
import Elmer.Spy


allFrenchSpies : List Elmer.Spy.Spy
allFrenchSpies =
    saveFrenchPhrasesSpy :: (withFrenchSettings allOnlineSpies)


allFrenchOfflineSpies : List Elmer.Spy.Spy
allFrenchOfflineSpies =
    saveFrenchPhrasesSpy :: (withFrenchSettings allOfflineSpies)


saveFrenchPhrasesSpy : Elmer.Spy.Spy
saveFrenchPhrasesSpy =
    Elmer.Spy.create "saveFrenchPhrases" (\_ -> Ports.LocalStorage.saveFrenchPhrases)
        |> Elmer.Spy.andCallFake (\_ -> Cmd.none)


withFrenchSettings : (String -> ( String, String, String ) -> String -> List Elmer.Spy.Spy) -> List Elmer.Spy.Spy
withFrenchSettings spyProducer =
    spyProducer "/api/phrases/french" ( "the-uuid", "c'est simple", "it's simple" ) "bonjour"
