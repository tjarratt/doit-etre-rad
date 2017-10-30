module IndexCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, li)
import Css.Namespace exposing (namespace)


type CssClasses
    = OfflineIndicator
    | PhraseListItem


type CssIds
    = Modes
    | AddPhraseForm
    | AddWordLabel
    | AddWordInput
    | AddWordSaveButton


css =
    (stylesheet << namespace "index")
        [ id AddPhraseForm
            [ margin (px 20)
            ]
        , id AddWordLabel [ fontSize (px 16) ]
        , id AddWordInput
            [ marginBottom (px 5)
            , fontSize (px 16)
            ]
        , id AddWordSaveButton
            [ fontSize (px 16) ]
        , class OfflineIndicator
            [ marginLeft (px 10) ]
        , class PhraseListItem
            [ fontSize (px 16) ]
        ]
