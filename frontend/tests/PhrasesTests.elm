module PhrasesTests exposing (..)

import Expect
import Test exposing (..)
import Phrases exposing (..)


translateTests : Test
translateTests =
    describe "adding a translation"
        [ test "to a saved phrase" <|
            \() ->
                let
                    phrase =
                        Saved { uuid = "uuid", content = "hi", translation = "" }

                    translated =
                        translate phrase "salut"
                in
                    Expect.equal (translationOf translated) "salut"
        , test "to an unsaved phrase" <|
            \() ->
                let
                    phrase =
                        Unsaved { content = "hi", translation = "" }

                    translated =
                        translate phrase "salut"
                in
                    Expect.equal (translationOf translated) "salut"
        ]


mergeTests : Test
mergeTests =
    describe "merging two lists of phrases"
        [ test "it filters out previously-saved phrases" <|
            \() ->
                let
                    oldPhrases =
                        [ Saved { uuid = "uuid", content = "hi", translation = "salut" }
                        , Unsaved { content = "whoops", translation = "" }
                        ]

                    newPhrases =
                        [ Saved { uuid = "uuid", content = "hi", translation = "salut" } ]

                    actual =
                        merge oldPhrases newPhrases
                in
                    Expect.equal actual oldPhrases
        , test "it filters out new, unsaved phrases" <|
            \() ->
                let
                    oldPhrases =
                        [ Saved { uuid = "uuid", content = "hi", translation = "salut" }
                        , Unsaved { content = "whoops", translation = "" }
                        ]

                    newPhrases =
                        [ Unsaved { content = "hi", translation = "" }
                        , Unsaved { content = "whoops", translation = "" }
                        , Unsaved { content = "cool", translation = "" }
                        ]

                    actual =
                        merge oldPhrases newPhrases

                    expected =
                        [ Saved { uuid = "uuid", content = "hi", translation = "salut" }
                        , Unsaved { content = "whoops", translation = "" }
                        , Unsaved { content = "cool", translation = "" }
                        ]
                in
                    Expect.equal actual expected
        , test "it keeps saved phrases rather than unsaved phrases" <|
            \() ->
                let
                    oldPhrases =
                        [ Unsaved { content = "dang", translation = "" } ]

                    newPhrases =
                        [ Saved { uuid = "uuid", content = "dang", translation = "zut" } ]

                    actual =
                        merge oldPhrases newPhrases
                in
                    Expect.equal actual newPhrases
        ]


equalTests : Test
equalTests =
    describe "equality"
        [ test "equal when content matches (given a translation is missing)" <|
            \() ->
                let
                    phrase1 =
                        Saved
                            { uuid = "uuid"
                            , content = "woah"
                            , translation = "woah"
                            }

                    phrase2 =
                        Unsaved { content = "woah", translation = "" }
                in
                    Expect.equal True (phraseEqual phrase1 phrase2)
        , test "is associative" <|
            \() ->
                let
                    phrase1 =
                        Saved
                            { uuid = "uuid"
                            , content = "woah"
                            , translation = "woah"
                            }

                    phrase2 =
                        Unsaved { content = "woah", translation = "" }
                in
                    Expect.equal True (phraseEqual phrase2 phrase1)
        , test "equal when content and translation matches" <|
            \() ->
                let
                    phrase1 =
                        Saved
                            { uuid = "uuid"
                            , content = "woah"
                            , translation = "woah"
                            }

                    phrase2 =
                        Saved
                            { uuid = "uuid"
                            , content = "woah"
                            , translation = "woah"
                            }
                in
                    Expect.equal True (phraseEqual phrase1 phrase2)
        , test "not equal when content differs" <|
            \() ->
                let
                    phrase1 =
                        Saved
                            { uuid = "uuid"
                            , content = "woah"
                            , translation = ""
                            }

                    phrase2 =
                        Saved
                            { uuid = "uuid"
                            , content = "nope"
                            , translation = ""
                            }
                in
                    Expect.equal False (phraseEqual phrase1 phrase2)
        , test "not equal when the translation differs" <|
            \() ->
                let
                    phrase1 =
                        Saved
                            { uuid = "uuid"
                            , content = "dang it"
                            , translation = "whoops"
                            }

                    phrase2 =
                        Saved
                            { uuid = "uuid"
                            , content = "dang it"
                            , translation = "zut alors"
                            }
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
                        Saved
                            { uuid = "uuid"
                            , content = "woah"
                            , translation = "woah"
                            }
                in
                    Expect.equal "woah" (Phrases.toString phrase)
        , test "works with unsaved phrases" <|
            \() ->
                let
                    phrase =
                        Unsaved { content = "hello world", translation = "" }
                in
                    Expect.equal "hello world" (Phrases.toString phrase)
        ]
