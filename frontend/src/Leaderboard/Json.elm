module Leaderboard.JSON
    exposing
        ( LeaderboardItem
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
