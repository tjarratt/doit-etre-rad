module LeaderboardTests exposing (..)

import Expect
import Fuzz exposing (string, int)
import Json.Decode as JD
import Json.Encode as JE
import Test exposing (..)
import Leaderboard exposing (..)
import Leaderboard.JSON exposing (..)


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
