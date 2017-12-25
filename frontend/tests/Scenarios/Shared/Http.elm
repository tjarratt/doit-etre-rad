module Scenarios.Shared.Http exposing (..)

import Http
import Json.Encode as JE
import Phrases exposing (..)
import Ports.LocalStorage as LocalStorage
import Elmer.Http
import Elmer.Http.Route
import Elmer.Http.Stub
import Elmer.Spy exposing (Spy)


httpSpies : String -> String -> String -> Spy
httpSpies endpoint phrase savedPhrase =
    Elmer.Http.serve
        [ stubbedGetResponse endpoint savedPhrase
        , stubbedPostResponse endpoint phrase
        ]


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


errorPostResponse endpoint phrase =
    stubbedPostResponse endpoint phrase
        |> Elmer.Http.Stub.withError Http.NetworkError


errorGetResponse endpoint phrase =
    stubbedGetResponse endpoint phrase
        |> Elmer.Http.Stub.withError Http.NetworkError
