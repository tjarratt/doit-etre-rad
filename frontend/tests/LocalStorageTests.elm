module LocalStorageTests exposing (..)

import Expect
import Fuzz exposing (string)
import Json.Decode as JD
import Json.Encode as JE
import Test exposing (..)
import Ports.LocalStorage exposing (..)
import Phrases exposing (..)


jsonEncodeDecodeTest : Test
jsonEncodeDecodeTest =
    describe "encoding and decoding phrases"
        [ fuzz2 string string "encoding captures a saved phrase's uuid and content" <|
            \uuid content ->
                let
                    phrase =
                        Saved { uuid = uuid, content = content }

                    expected =
                        JE.object
                            [ ( "type", JE.string "SAVED" )
                            , ( "uuid", JE.string uuid )
                            , ( "content", JE.string content )
                            ]

                    actual =
                        phraseEncoder phrase
                in
                    Expect.equal actual expected
        , fuzz string "encoding captures an unsaved phrases content" <|
            \content ->
                let
                    phrase =
                        Unsaved content

                    expected =
                        JE.object
                            [ ( "type", JE.string "UNSAVED" )
                            , ( "content", JE.string content )
                            ]

                    actual =
                        phraseEncoder phrase
                in
                    Expect.equal actual expected
        , fuzz string "phraseDecoder maps bare strings to Phrases" <|
            \content ->
                let
                    json =
                        JE.object
                            [ ( "type", JE.string "UNSAVED" )
                            , ( "content", JE.string content )
                            ]
                in
                    JD.decodeValue phraseDecoder json
                        |> Expect.equal
                            (Ok <| Unsaved content)
        , fuzz2 string string "phraseDecoder maps uuids and strings to Phrases" <|
            \content uuid ->
                let
                    json =
                        JE.object
                            [ ( "type", JE.string "UNSAVED" )
                            , ( "uuid", JE.string uuid )
                            , ( "content", JE.string content )
                            ]
                in
                    JD.decodeValue phraseDecoder json
                        |> Expect.equal
                            (Ok <| Saved { uuid = uuid, content = content })
        ]
