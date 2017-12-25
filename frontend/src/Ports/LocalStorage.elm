port module Ports.LocalStorage
    exposing
        ( saveFrenchPhrases
        , saveEnglishPhrases
        , setItemResponse
        , getItem
        , getItemResponse
        , setUserUuid
        , getUserUuid
        , getUserUuidResponse
        , phraseEncoder
        , phraseDecoder
        )

{-| This module is just a dumb wrapper around window.localStorage


# Simpler wrappers

@docs setItemResponse, getItem, getItemResponse


# Slightly-higher-level wrappers for specific keys (user uuid, phrases, etc...)

@docs setUserUuid, getUserUuid, getUserUuidResponse, saveFrenchPhrases, saveEnglishPhrases


# JSON supports

@docs phraseEncoder, phraseDecoder

-}

import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as JE
import Phrases


{-| a better wrapper around setItem for Phrases in french
-}
saveFrenchPhrases : ( List Phrases.Phrase, String ) -> Cmd msg
saveFrenchPhrases ( phrases, newPhrase ) =
    setItem
        ( "frenchPhrases"
        , JE.list <| List.map phraseEncoder phrases
        , newPhrase
        )


{-| a better wrapper around setItem for Phrases in english
-}
saveEnglishPhrases : ( List Phrases.Phrase, String ) -> Cmd msg
saveEnglishPhrases ( phrases, newPhrase ) =
    setItem
        ( "englishPhrases"
        , JE.list <| List.map phraseEncoder phrases
        , newPhrase
        )


{-| a json encoder for Phrases, appropriate for local storage
-}
phraseEncoder : Phrases.Phrase -> JE.Value
phraseEncoder phrase =
    case phrase of
        Phrases.Saved p ->
            JE.object
                [ ( "type", JE.string "SAVED" )
                , ( "uuid", JE.string p.uuid )
                , ( "content", JE.string p.content )
                , ( "translation", JE.string p.translation )
                ]

        Phrases.Unsaved p ->
            JE.object
                [ ( "type", JE.string "UNSAVED" )
                , ( "content", JE.string p.content )
                , ( "translation", JE.string p.translation )
                ]


{-| a json decoder for Phrases, appropriate for local storage
-}
phraseDecoder : JD.Decoder Phrases.Phrase
phraseDecoder =
    JD.oneOf
        [ savedPhraseDecoder
        , unsavedPhraseDecoder
        ]


savedPhraseDecoder : JD.Decoder Phrases.Phrase
savedPhraseDecoder =
    JD.map Phrases.Saved <|
        (decode
            Phrases.SavedPhrase
            |> (required "uuid" JD.string)
            |> (required "content" JD.string)
            |> (required "translation" JD.string)
        )


unsavedPhraseDecoder : JD.Decoder Phrases.Phrase
unsavedPhraseDecoder =
    JD.map Phrases.Unsaved <|
        (decode
            Phrases.UnsavedPhrase
            |> (required "content" JD.string)
            |> (required "translation" JD.string)
        )


port setItem : ( String, JD.Value, String ) -> Cmd msg


{-| generic response to indicate that a value has been saved to local storage
-}
port setItemResponse : (JD.Value -> msg) -> Sub msg


{-| a port to request a value from local storage
-}
port getItem : String -> Cmd msg


{-| a generic reponse for a requested value from local storage
-}
port getItemResponse : (( String, Maybe JE.Value ) -> msg) -> Sub msg


{-| a higher-level wrapper around setItem
-}
port setUserUuid : String -> Cmd msg


{-| a slightly more type-safe versin of getItem
-}
port getUserUuid : () -> Cmd msg


port getUserUuidResponse : (Maybe String -> msg) -> Sub msg
