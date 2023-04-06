module Styles exposing (..)

import Color exposing (Color)
import Element exposing (height, px, rgb255, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as Attributes
import Material.Icons.Types
import Widget exposing (..)
import Widget.Customize
import Widget.Icon
import Widget.Material as Material exposing (Palette)
import Widget.Material.Color as MaterialColor
import Widget.Material.Typography as Typography


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


smallIconButton : ButtonStyle msg
smallIconButton =
    iconButton
        |> Widget.Customize.elementButton
            [ Element.height <| Element.px 28
            , Element.width <| Element.minimum 28 <| Element.shrink
            , Element.padding 2
            ]


iconMapper : Material.Icons.Types.Icon msg -> Widget.Icon.Icon msg
iconMapper icon =
    Widget.Icon.elmMaterialIcons Material.Icons.Types.Color icon


tab : TabStyle msg
tab =
    Material.tab appPalette


fateChartBackgroundColor : Element.Attr decorative msg
fateChartBackgroundColor =
    Background.color (rgb255 187 222 251)


meaningTableBackgroundColor : Element.Attr decorative msg
meaningTableBackgroundColor =
    Background.color (rgb255 232 245 233)


randomEventBackgroundColor : Element.Attr decorative msg
randomEventBackgroundColor =
    Background.color (rgb255 251 233 231)


baseButton : Palette -> ButtonStyle msg
baseButton palette =
    { elementButton =
        Typography.button
            ++ [ Element.height <| Element.px 36
               , Element.paddingXY 8 8
               , Border.rounded <| 4
               ]
    , ifDisabled =
        [ Element.htmlAttribute <| Attributes.style "cursor" "not-allowed"
        ]
    , ifActive = []
    , otherwise = []
    , content =
        { elementRow =
            [ Element.spacing <| 8
            , Element.width <| Element.minimum 32 <| Element.shrink
            , Element.centerY
            ]
        , content =
            { text = { contentText = [ Element.centerX ] }
            , icon =
                { ifDisabled =
                    { size = 18
                    , color = gray palette
                    }
                , ifActive =
                    { size = 18
                    , color = gray palette
                    }
                , otherwise =
                    { size = 18
                    , color = gray palette
                    }
                }
            }
        }
    }


gray : Palette -> Color
gray palette =
    palette.surface
        |> MaterialColor.withShade palette.on.surface 0.5
