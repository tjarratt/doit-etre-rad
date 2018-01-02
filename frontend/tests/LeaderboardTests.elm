module LeaderboardTests exposing (jsonEncodeDecodeTest)

import Expect
import Fuzz exposing (string, int)
import Json.Decode as JD
import Json.Encode as JE
import Test exposing (Test, describe, fuzz2)
import Components.Leaderboard.JSON exposing (LeaderboardItem, leaderboardItemDecoder)


jsonEncodeDecodeTest : Test
jsonEncodeDecodeTest =
    describe "decoding"
        [ fuzz2 string int "leaderboard items" <|
            (\userUuid phraseCount ->
                let
                    expectedValue =
                        Ok <| LeaderboardItem userUuid phraseCount

                    json =
                        JE.object
                            [ ( "userUuid", JE.string userUuid )
                            , ( "phraseCount", JE.int phraseCount )
                            ]

                    decodedValue =
                        JD.decodeValue leaderboardItemDecoder json
                in
                    Expect.equal decodedValue expectedValue
            )
        ]
