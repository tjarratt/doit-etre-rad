module IndexCss exposing (css, CssClasses(..), CssIds(..))

import Css exposing (..)
import Css.Namespace exposing (namespace)


type CssClasses
    = OfflineIndicator
    | PhraseListItem
    | AddPhraseTranslation
    | AddTranslationLabel
    | CardContainer
    | CardFlipper
    | CardFront
    | CardBack
    | Flip
    | AddTranslationButton
    | CancelTranslationButton
    | LeaderboardItem
    | CenterMe


type CssIds
    = LandingPage
    | Header
    | Modes
    | PracticeFrench
    | PracticeEnglish
    | Back
    | AddPhraseForm
    | PracticePhrases
    | AddWordLabel
    | AddWordInput
    | AddWordSaveButton
    | PhraseList
    | SecretButton
    | AdminSection
    | Leaderboard
    | PasswordField
    | Errors


css : Css.Stylesheet
css =
    (stylesheet << namespace "index")
        [ id LandingPage
            [ textAlign center ]
        , id Header
            [ textAlign center ]
        , id Modes
            [ marginBottom (px 10) ]
        , id SecretButton
            [ position absolute
            , bottom (px 10)
            ]
        , id Errors
            [ borderRadius (px 8)
            , padding (px 10)
            ]
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
        , class CenterMe
            [ textAlign center ]
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
        , class AddPhraseTranslation
            []
        , class CardContainer
            [ transform (perspective 1000)
            , width inherit
            , height (px 100)
            ]
        , class CardFlipper
            [ position relative
            , property "transition" "0.6s"
            , property "transform-style" "preserve-3d"
            , withClass Flip
                [ transform (rotateY (deg 180)) ]
            ]
        , class CardFront
            [ position absolute
            , property "backface-visibility" "hidden"
            , top (px 0)
            , left (px 0)
            , right (px 0)
            , height (px 100)

            -- applies only to front
            , property "z-index" "2"
            , property "transform" "rotateY(0deg)"
            ]
        , class CardBack
            [ position absolute
            , property "backface-visibility" "hidden"
            , top (px 0)
            , left (px 0)
            , right (px 0)
            , height (px 100)

            -- applies only to back
            , property "transform" "rotateY(180deg)"
            ]
        , id AdminSection [ textAlign center ]
        , class LeaderboardItem
            [ marginRight (px 10) ]
        ]
