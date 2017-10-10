port module Ports.LocalStorage exposing (..)

{-| This is just a dumb wrapper around window.localStorage


# setItem

@docs setItem


# setItemResponse

@docs setItemResponse


# getItem

@docs getItem


# callback for getItem

@docs getItemResponse


# set user uuid

@docs setUserUuid


# get user uuid

@docs getUserUuid


# callback for getUserUuid

@docs getUserUuidResponse

-}

import Json.Decode as JD
import Json.Encode as JE


-- port for saving a json-encoded value with a key in local storage


port setItem : ( String, JD.Value ) -> Cmd msg



-- port for acknowledging that we saved a json-encoded value in local storage


port setItemResponse : (JD.Value -> msg) -> Sub msg



-- port for retrieving previously-saved json encoded values in local storage


port getItem : String -> Cmd msg



-- subscribe part of getItem port


port getItemResponse : (( String, Maybe JE.Value ) -> msg) -> Sub msg



-- port for setting user's uuid


port setUserUuid : String -> Cmd msg



-- port for getting user's uuid


port getUserUuid : String -> Cmd msg



-- port subscribe part of getUserUuid


port getUserUuidResponse : (Maybe String -> msg) -> Sub msg
