module Scenarios.Shared.Http exposing (..)

import Http
import Json.Encode as JE
import Phrases exposing (..)
import Ports.LocalStorage as LocalStorage
import Elmer.Http
import Elmer.Http.Route
import Elmer.Http.Stub
import Elmer.Spy exposing (Spy)


offlineSpies : String -> String -> String -> Spy
offlineSpies endpoint phrase1 phrase2 =
    Elmer.Http.serve
        [ errorGetResponse endpoint phrase1
        , errorPostResponse endpoint phrase2
        ]


stubbedGetResponse : String -> String -> Elmer.Http.HttpResponseStub
stubbedGetResponse endpoint phrase =
    Elmer.Http.Stub.for (Elmer.Http.Route.get endpoint)
        |> Elmer.Http.Stub.withBody
            (JE.encode 0 <|
                JE.list
                    [ (LocalStorage.phraseEncoder
                        (Saved
                            { uuid = "uuid_" ++ phrase
                            , content = phrase
                            , translation = ""
                            }
                        )
                      )
                    ]
            )


stubbedPostResponse : String -> String -> Elmer.Http.HttpResponseStub
stubbedPostResponse endpoint phrase =
    Elmer.Http.Stub.for (Elmer.Http.Route.post endpoint)
        |> Elmer.Http.Stub.withBody
            (JE.encode 0
                (LocalStorage.phraseEncoder
                    (Saved
                        { uuid = "uuid_" ++ phrase
                        , content = phrase
                        , translation = ""
                        }
                    )
                )
            )


stubbedPutResponse : String -> ( String, String, String ) -> Elmer.Http.HttpResponseStub
stubbedPutResponse endpoint ( uuid, phrase, translation ) =
    Elmer.Http.Stub.for (Elmer.Http.Route.put <| endpoint ++ "/" ++ uuid)
        |> Elmer.Http.Stub.withBody
            (JE.encode 0
                (JE.object
                    [ ( "uuid", JE.string uuid )
                    , ( "content", JE.string phrase )
                    , ( "translation", JE.string translation )
                    ]
                )
            )


errorPostResponse : String -> String -> Elmer.Http.HttpResponseStub
errorPostResponse endpoint phrase =
    stubbedPostResponse endpoint phrase
        |> Elmer.Http.Stub.withError Http.NetworkError


errorGetResponse : String -> String -> Elmer.Http.HttpResponseStub
errorGetResponse endpoint phrase =
    stubbedGetResponse endpoint phrase
        |> Elmer.Http.Stub.withError Http.NetworkError
