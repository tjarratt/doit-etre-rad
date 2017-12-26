module Scenarios.TestSetup exposing (..)

import App
import Elmer
import Elmer.Spy


type alias TestSetup =
    { allSpies : List Elmer.Spy.Spy
    , expectedEndpoint : String
    , expectedTitle : String
    , getItemSpyName : String
    , inputPhrase1 : String
    , inputPhrase2 : String
    , inputTranslation1 : String
    , language : String
    , localStorageSpyName : String
    , savedPhrase : String
    , startActivityScenario :
        Elmer.TestState App.Model App.Msg -> Elmer.TestState App.Model App.Msg
    }
