module Scenarios.TestSetup exposing (..)

import App
import Elmer
import Elmer.Spy


type alias TestSetup =
    { allSpies : List Elmer.Spy.Spy
    , readEndpoint : String
    , createEndpoint : String
    , updateEndpoint : String -> String
    , expectedTitle : String
    , getItemSpyName : String
    , inputPhrase1 : String
    , inputPhrase2 : String
    , inputTranslation1 : String
    , language : String
    , localStorageSpyName : String
    , savedPhrase : String
    , startActivityScenario :
        Elmer.TestState App.ApplicationState App.Msg -> Elmer.TestState App.ApplicationState App.Msg
    }
