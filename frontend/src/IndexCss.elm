module IndexCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, li)
import Css.Namespace exposing (namespace)


type CssClasses
    = OfflineIndicator
    | PhraseListItem


type CssIds
    = LandingPage
    | Modes
    | AddPhraseForm
    | AddWordLabel
    | AddWordInput
    | AddWordSaveButton
    | PhraseList


css =
    (stylesheet << namespace "index")
        [ id LandingPage
            [ textAlign center ]
        , id Modes
            [ marginBottom (px 10) ]
        , id AddPhraseForm
            [ margin (px 20)
            , paddingBottom (px 20)
            , borderBottom3 (px 2) dashed (rgb 204 204 204)
            ]
        , id AddWordLabel [ fontSize (px 16) ]
        , id AddWordInput
            [ marginBottom (px 5)
            , fontSize (px 16)
            ]
        , id AddWordSaveButton
            [ fontSize (px 16) ]
        , id PhraseList
            [ listStyleType none
            , padding (px 0)
            ]
        , class OfflineIndicator
            [ marginLeft (px 10) ]
        , class PhraseListItem
            [ fontSize (px 16)
            , margin (px 25)
            , border3 (px 1) solid (rgb 204 204 204)
            , padding (px 10)
            , textAlign center
            , borderRadius (px 4)
            ]
        ]
