port module Ports.LocalStorage
    exposing
        ( saveFrenchPhrases
        , saveEnglishPhrases
        , setItemResponse
        , getItem
        , getItemResponse
        , getUserUuid
        , getUserUuidResponse
        , phraseEncoder
        , phraseDecoder
        , savedPhraseDecoder
        )

{-| This module is just a dumb wrapper around window.localStorage


# Simpler wrappers

@docs setItemResponse, getItem, getItemResponse


# Slightly-higher-level wrappers for specific keys (user uuid, phrases, etc...)

@docs getUserUuid, getUserUuidResponse, saveFrenchPhrases, saveEnglishPhrases


# JSON supports

@docs phraseEncoder, phraseDecoder, savedPhraseDecoder

-}

import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as JE
import Phrases


{-| a better wrapper around setItem for Phrases in french
-}
saveFrenchPhrases : ( List Phrases.Phrase, Phrases.Phrase ) -> Cmd msg
saveFrenchPhrases args =
    savePhrases "frenchPhrases" args


{-| a better wrapper around setItem for Phrases in english
-}
saveEnglishPhrases : ( List Phrases.Phrase, Phrases.Phrase ) -> Cmd msg
saveEnglishPhrases args =
    savePhrases "englishPhrases" args


savePhrases : String -> ( List Phrases.Phrase, Phrases.Phrase ) -> Cmd msg
savePhrases key ( phrases, newPhrase ) =
    setItem
        ( key
        , JE.list <| List.map phraseEncoder phrases
        , phraseEncoder newPhrase
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


{-| a json decoder for SavedPhrases, appropriate for local storage
-}
savedPhraseDecoder : JD.Decoder Phrases.Phrase
savedPhraseDecoder =
    JD.map Phrases.Saved <|
        (decode
            Phrases.SavedPhrase
            |> (required "uuid" JD.string)
            |> (required "content" JD.string)
            |> (required "translation" JD.string)
        )


{-| a json decoder for UnsavedPhrases, appropriate for local storage
-}
unsavedPhraseDecoder : JD.Decoder Phrases.Phrase
unsavedPhraseDecoder =
    JD.map Phrases.Unsaved <|
        (decode
            Phrases.UnsavedPhrase
            |> (required "content" JD.string)
            |> (required "translation" JD.string)
        )


port setItem : ( String, JD.Value, JD.Value ) -> Cmd msg


{-| generic response to indicate that a value has been saved to local storage
-}
port setItemResponse : (JD.Value -> msg) -> Sub msg


{-| a port to request a value from local storage
-}
port getItem : String -> Cmd msg


{-| a generic reponse for a requested value from local storage
-}
port getItemResponse : (( String, Maybe JE.Value ) -> msg) -> Sub msg


{-| a slightly more type-safe version of getItem
-}
port getUserUuid : () -> Cmd msg


port getUserUuidResponse : (String -> msg) -> Sub msg
