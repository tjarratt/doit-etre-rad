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
    describe "encoding and decoding"
        [ fuzz3 string string string "phraseEncoder handles saved phrases" <|
            \uuid content translation ->
                let
                    phrase =
                        Saved { uuid = uuid, content = content, translation = translation }

                    expected =
                        JE.object
                            [ ( "type", JE.string "SAVED" )
                            , ( "uuid", JE.string uuid )
                            , ( "content", JE.string content )
                            , ( "translation", JE.string translation )
                            ]

                    actual =
                        phraseEncoder phrase
                in
                    Expect.equal actual expected
        , fuzz2 string string "phraseEncoder handles unsaved phrases" <|
            \content translation ->
                let
                    phrase =
                        Unsaved { content = content, translation = translation }

                    expected =
                        JE.object
                            [ ( "type", JE.string "UNSAVED" )
                            , ( "content", JE.string content )
                            , ( "translation", JE.string translation )
                            ]

                    actual =
                        phraseEncoder phrase
                in
                    Expect.equal actual expected
        , fuzz2 string string "phraseDecoder maps Unsaved Phrases" <|
            \content translation ->
                let
                    json =
                        JE.object
                            [ ( "type", JE.string "UNSAVED" )
                            , ( "content", JE.string content )
                            , ( "translation", JE.string translation )
                            ]
                in
                    JD.decodeValue phraseDecoder json
                        |> Expect.equal
                            (Ok <| Unsaved { content = content, translation = translation })
        , fuzz3 string string string "phraseDecoder maps Saved Phrases" <|
            \content uuid translation ->
                let
                    json =
                        JE.object
                            [ ( "type", JE.string "UNSAVED" )
                            , ( "uuid", JE.string uuid )
                            , ( "content", JE.string content )
                            , ( "translation", JE.string translation )
                            ]
                in
                    JD.decodeValue phraseDecoder json
                        |> Expect.equal
                            (Ok <| Saved { uuid = uuid, content = content, translation = translation })
        ]
