module Scenarios.English exposing (allEnglishSpies)

import Ports.LocalStorage
import Scenarios.Shared.Spies exposing (allOnlineSpies, allOfflineSpies)
import Elmer.Spy


allEnglishSpies : List Elmer.Spy.Spy
allEnglishSpies =
    saveEnglishPhrasesSpy :: (withEnglishSettings allOnlineSpies)


saveEnglishPhrasesSpy : Elmer.Spy.Spy
saveEnglishPhrasesSpy =
    Elmer.Spy.create "saveEnglishPhrases" (\_ -> Ports.LocalStorage.saveEnglishPhrases)
        |> Elmer.Spy.andCallFake (\_ -> Cmd.none)


withEnglishSettings : (String -> ( String, String, String ) -> String -> List Elmer.Spy.Spy) -> List Elmer.Spy.Spy
withEnglishSettings spyProducer =
    spyProducer "/api/phrases/english" ( "the-uuid", "it's simple", "c'est simple" ) "hello"
