module Phrases
    exposing
        ( Phrase(..)
        , SavedPhrase
        , UnsavedPhrase
        , merge
        , toString
        , phraseEqual
        , translate
        , translationOf
        , isUnsaved
        )

import List


type Phrase
    = Saved SavedPhrase
    | Unsaved UnsavedPhrase


type alias SavedPhrase =
    { uuid : String
    , content : String
    , translation : String
    }


type alias UnsavedPhrase =
    { content : String
    , translation : String
    }


merge : List Phrase -> List Phrase -> List Phrase
merge oldPhrases newPhrases =
    let
        ( oldSaved, oldUnsaved ) =
            splitPhrases oldPhrases

        ( newSaved, newUnsaved ) =
            splitPhrases newPhrases

        uniqueSavedPhrases =
            List.append oldSaved (List.filter (\p -> phraseNotInList oldSaved p) newSaved)

        uniqueUnsavedPhrases =
            List.append oldUnsaved (List.filter (\p -> phraseNotInList oldUnsaved p) newUnsaved)

        savedContent =
            List.map toString uniqueSavedPhrases

        filterAlreadySeen =
            List.filter
                (\phrase ->
                    not <| List.member (toString phrase) savedContent
                )
    in
        List.append uniqueSavedPhrases (filterAlreadySeen uniqueUnsavedPhrases)


phraseNotInList : List Phrase -> Phrase -> Bool
phraseNotInList phraseList phrase =
    List.all
        (\p ->
            not <| phraseEqual p phrase
        )
        phraseList


splitPhrases : List Phrase -> ( List Phrase, List Phrase )
splitPhrases phrases =
    let
        filterSaved =
            List.filter <| not << isUnsaved

        filterUnsaved =
            List.filter isUnsaved
    in
        ( (filterSaved phrases), (filterUnsaved phrases) )


phraseEqual : Phrase -> Phrase -> Bool
phraseEqual p1 p2 =
    case ( p1, p2 ) of
        ( Saved _, Unsaved _ ) ->
            (toString p1) == (toString p2)

        ( Unsaved _, Saved _ ) ->
            (toString p1) == (toString p2)

        ( _, _ ) ->
            let
                contentEqual =
                    (toString p1)
                        == (toString p2)

                translationEqual =
                    (translationOf p1)
                        == (translationOf p2)
            in
                contentEqual && translationEqual


toString : Phrase -> String
toString phrase =
    case phrase of
        Saved p ->
            p.content

        Unsaved p ->
            p.content


translationOf : Phrase -> String
translationOf phrase =
    case phrase of
        Saved p ->
            p.translation

        Unsaved p ->
            p.translation


translate : Phrase -> String -> Phrase
translate phrase translation =
    case phrase of
        Saved savedPhrase ->
            Saved { savedPhrase | translation = translation }

        Unsaved unsavedPhrase ->
            Unsaved { unsavedPhrase | translation = translation }


isUnsaved : Phrase -> Bool
isUnsaved phrase =
    case phrase of
        Saved savedPhrase ->
            False

        Unsaved unsavedPhrase ->
            True
