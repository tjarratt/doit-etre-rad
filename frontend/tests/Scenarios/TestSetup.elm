module Scenarios.TestSetup exposing (TestSetup)

import App
import Activities
import Elmer


type alias TestSetup =
    { readEndpoint : String
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
    , activity : Activities.Activity
    }
