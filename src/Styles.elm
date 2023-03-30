module Styles exposing (..)

import Widget exposing (..)
import Widget.Material as Material exposing (Palette)


appPalette : Palette
appPalette =
    Material.defaultPalette


containedButton : ButtonStyle msg
containedButton =
    Material.containedButton appPalette


textButton : ButtonStyle msg
textButton =
    Material.textButton appPalette


outlinedButton : ButtonStyle msg
outlinedButton =
    Material.outlinedButton appPalette
