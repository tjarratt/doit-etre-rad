port module Stylesheets exposing (main)

import Css.File exposing (CssCompilerProgram, CssFileStructure)
import IndexCss


port files : CssFileStructure -> Cmd msg


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "index.css", Css.File.compile [ IndexCss.css ] ) ]
