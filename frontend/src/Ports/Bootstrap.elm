port module Ports.Bootstrap exposing (showTooltips)

{-| This module is just a dumb wrapper around
asking jquery to render bootstrap tooltips
-}


port showTooltips : () -> Cmd msg
