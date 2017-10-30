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



{-
   * capture all of the saved phrases
   * add "old" unsaved that aren't already in the list
   * add "new" unsaved that aren't already in the list
-}


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
            List.map phraseToString uniqueSavedPhrases

        filterAlreadySeen =
            List.filter
                (\phrase ->
                    not <| List.member (phraseToString phrase) savedContent
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
            List.filter
                (\phrase ->
                    case phrase of
                        Unsaved _ ->
                            False

                        Saved _ ->
                            True
                )

        filterUnsaved =
            List.filter
                (\phrase ->
                    case phrase of
                        Unsaved _ ->
                            True

                        Saved _ ->
                            False
                )
    in
        ( (filterSaved phrases), (filterUnsaved phrases) )


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
