module PhrasesTests exposing (..)

import Expect
import Test exposing (..)
import Phrases exposing (..)


mergeTests : Test
mergeTests =
    describe "merging two lists of phrases"
        [ test "it filters out previously-saved phrases" <|
            \() ->
                let
                    oldPhrases =
                        [ Saved { uuid = "uuid", content = "hi" }
                        , Unsaved "whoops"
                        ]

                    newPhrases =
                        [ Saved { uuid = "uuid", content = "hi" } ]

                    actual =
                        merge oldPhrases newPhrases
                in
                    Expect.equal actual oldPhrases
        , test "it filters out new, unsaved phrases" <|
            \() ->
                let
                    oldPhrases =
                        [ Saved { uuid = "uuid", content = "hi" }
                        , Unsaved "whoops"
                        ]

                    newPhrases =
                        [ Unsaved "hi"
                        , Unsaved "whoops"
                        , Unsaved "cool"
                        ]

                    actual =
                        merge oldPhrases newPhrases

                    expected =
                        [ Saved { uuid = "uuid", content = "hi" }
                        , Unsaved "whoops"
                        , Unsaved "cool"
                        ]
                in
                    Expect.equal actual expected
        ]


equalTests : Test
equalTests =
    describe "equality"
        [ test "equal when content matches" <|
            \() ->
                let
                    phrase1 =
                        Saved { uuid = "uuid", content = "woah" }

                    phrase2 =
                        Unsaved "woah"
                in
                    Expect.equal True (phraseEqual phrase1 phrase2)
        , test "not equal when content differs" <|
            \() ->
                let
                    phrase1 =
                        Saved { uuid = "uuid", content = "woah" }

                    phrase2 =
                        Saved { uuid = "uuid", content = "nope" }
                in
                    Expect.equal False (phraseEqual phrase1 phrase2)
        ]


toStringTests : Test
toStringTests =
    describe "phraseToString"
        [ test "works with saved phrases" <|
            \() ->
                let
                    phrase =
                        Saved { uuid = "uuid", content = "woah" }
                in
                    Expect.equal "woah" (phraseToString phrase)
        , test "works with unsaved phrases" <|
            \() ->
                let
                    phrase =
                        Unsaved "hello world"
                in
                    Expect.equal "hello world" (phraseToString phrase)
        ]
