module Scenarios.Shared
    exposing
        ( loggedInUser
        , defaultLocation
        , loggedInUserUuid
        , loggedInUserUuidString
        )

import App
import Uuid exposing (Uuid)
import Navigation


loggedInUser : App.ApplicationState
loggedInUser =
    let
        ( appState, _ ) =
            App.init { seed = 0 } defaultLocation
    in
        { appState | userUuid = Just loggedInUserUuid }


loggedInUserUuid : Uuid
loggedInUserUuid =
    case Uuid.fromString loggedInUserUuidString of
        Nothing ->
            Debug.crash "Daaaaang. Uuids are not Uuids."

        Just uuid ->
            uuid


loggedInUserUuidString : String
loggedInUserUuidString =
    "2a09efcb-514d-4ce2-a5db-8fc7edc984fb"


defaultLocation : Navigation.Location
defaultLocation =
    { href = ""
    , host = ""
    , hostname = ""
    , protocol = ""
    , origin = ""
    , port_ = ""
    , pathname = ""
    , search = ""
    , hash = ""
    , username = ""
    , password = ""
    }
