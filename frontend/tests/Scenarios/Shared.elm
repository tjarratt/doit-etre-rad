module Scenarios.Shared
    exposing
        ( practiceActivityTests
        , defaultModel
        )

import App
import Elmer exposing ((<&&>), atIndex, hasLength)
import Elmer.Platform.Subscription as Subscription
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Elmer.Spy.Matchers exposing (stringArg, typedArg, wasCalled, wasCalledWith)
import Scenarios.French exposing (allFrenchOfflineSpies, allFrenchSpies)
import Scenarios.Shared.Spies exposing (practiceComponentSpy)
import Scenarios.TestSetup exposing (TestSetup)
import Test exposing (describe, test, Test)


practiceActivityTests : TestSetup -> Test
practiceActivityTests setup =
    describe ("when practicing " ++ setup.language ++ " phrases...")
        [ test "it initially queries local storage for the phrases it previously saved" <|
            \() ->
                Elmer.given defaultModel App.view App.update
                    |> Spy.use (practiceComponentSpy :: allFrenchSpies)
                    |> Subscription.with (\() -> App.subscriptions)
                    |> Subscription.send "userUuidResponseEffect" "941ee33c-725d-45f7-b6a7-908b3d1a2437"
                    |> setup.startActivityScenario
                    |> Spy.expect "practiceComponentLoadSpy" (wasCalled 1)
        ]


defaultModel : App.ApplicationState
defaultModel =
    let
        ( appState, _ ) =
            App.init { seed = 0 }
    in
        appState
