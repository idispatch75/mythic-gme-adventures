module Styles exposing (..)

import Material.Icons.Types
import Widget exposing (..)
import Widget.Icon
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


iconButton : ButtonStyle msg
iconButton =
    Material.iconButton appPalette


iconMapper : Material.Icons.Types.Icon msg -> Widget.Icon.Icon msg
iconMapper icon =
    Widget.Icon.elmMaterialIcons Material.Icons.Types.Color icon


tab : TabStyle msg
tab =
    Material.tab appPalette
