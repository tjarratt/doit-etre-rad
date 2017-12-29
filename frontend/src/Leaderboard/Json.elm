module Leaderboard.JSON
    exposing
        ( LeaderboardItem
        , Error
        , LeaderboardResult(..)
        , decoder
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


type alias Error =
    { error : String }


errorDecoder : JD.Decoder Error
errorDecoder =
    JD.map Error
        (JD.field "error" JD.string)


type LeaderboardResult
    = Success (List LeaderboardItem)
    | Failure Error


successDecoder : JD.Decoder LeaderboardResult
successDecoder =
    JD.map Success <| JD.list leaderboardItemDecoder


fooErrorDecoder : JD.Decoder LeaderboardResult
fooErrorDecoder =
    JD.map Failure errorDecoder


decoder : JD.Decoder LeaderboardResult
decoder =
    JD.oneOf [ successDecoder, fooErrorDecoder ]
