module Phrases
    exposing
        ( Phrase(..)
        , SavedPhrase
        , merge
        , phraseToString
        , phraseEqual
        )

import List


type Phrase
    = Saved SavedPhrase
    | Unsaved String


type alias SavedPhrase =
    { uuid : String
    , content : String
    }


merge : List Phrase -> List Phrase -> List Phrase
merge oldPhrases newPhrases =
    let
        oldContent =
            List.map phraseToString oldPhrases
    in
        newPhrases
            |> List.filter
                (\phrase ->
                    not <| List.member (phraseToString phrase) oldContent
                )
            |> List.append oldPhrases


phraseEqual : Phrase -> Phrase -> Bool
phraseEqual p1 p2 =
    (phraseToString p1)
        == (phraseToString p2)


phraseToString : Phrase -> String
phraseToString phrase =
    case phrase of
        Saved p ->
            p.content

        Unsaved str ->
            str
