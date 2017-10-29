module IndexCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, li)
import Css.Namespace exposing (namespace)


type CssClasses
    = CurrentWordLabel


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
        , id AddWordLabel []
        , id AddWordInput
            [ marginBottom (px 5)
            ]
        , id AddWordSaveButton
            []
        ]
