module Components.Leaderboard.JSON
    exposing
        ( LeaderboardItem
        , decoder
        , errorDecoder
        , leaderboardItemDecoder
        )

import Json.Decode as JD


type alias LeaderboardItem =
    { userUuid : String
    , phraseCount : Int
    }


leaderboardItemDecoder : JD.Decoder LeaderboardItem
leaderboardItemDecoder =
    JD.map2 LeaderboardItem
        (JD.field "userUuid" JD.string)
        (JD.field "phraseCount" JD.int)


decoder : JD.Decoder (List LeaderboardItem)
decoder =
    JD.list leaderboardItemDecoder


errorDecoder : String -> String
errorDecoder responseBody =
    let
        decoder =
            JD.field "error" JD.string

        result =
            JD.decodeString decoder responseBody
    in
        case result of
            Ok errorMessage ->
                errorMessage

            _ ->
                "something bad happened, bro"
