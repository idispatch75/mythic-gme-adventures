module Styles exposing (..)

import Color
import Dropbox exposing (Msg)
import Element exposing (height, px, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as Attributes
import Material.Icons.Types
import Widget exposing (..)
import Widget.Customize
import Widget.Icon
import Widget.Material as Material exposing (Palette)
import Widget.Material.Color as MaterialColor exposing (textAndBackground)
import Widget.Material.Typography as Typography


appPalette : Palette
appPalette =
    Material.defaultPalette


containedButton : ButtonStyle msg
containedButton =
    Material.containedButton appPalette
        |> Widget.Customize.elementButton [ Element.focused [] ]


textButton : ButtonStyle msg
textButton =
    Material.textButton appPalette
        |> Widget.Customize.elementButton [ Element.focused [] ]


outlinedButton : ButtonStyle msg
outlinedButton =
    Material.outlinedButton appPalette
        |> Widget.Customize.elementButton [ Element.focused [] ]


iconButton : ButtonStyle msg
iconButton =
    Material.iconButton appPalette
        |> Widget.Customize.elementButton [ Element.focused [] ]


smallIconButton : ButtonStyle msg
smallIconButton =
    iconButton
        |> Widget.Customize.elementButton
            [ Element.height <| Element.px 28
            , Element.width <| Element.minimum 28 <| Element.shrink
            , Element.padding 2
            ]


textInput : TextInputStyle msg
textInput =
    Material.textInput appPalette


iconMapper : Material.Icons.Types.Icon msg -> Widget.Icon.Icon msg
iconMapper icon =
    Widget.Icon.elmMaterialIcons Material.Icons.Types.Color icon


tab : TabStyle msg
tab =
    Material.tab appPalette


type alias RollColors decorative msg =
    { background : Element.Attr decorative msg
    , header : List (Element.Attr () msg)
    }


fateChartColors : RollColors decorative msg
fateChartColors =
    { background = Background.color (Element.rgb255 187 222 251)
    , header = textAndBackground (Color.rgb255 13 71 161)
    }


meaningTableColors : RollColors decorative msg
meaningTableColors =
    { background = Background.color (Element.rgb255 232 245 233)
    , header = textAndBackground (Color.rgb255 27 94 32)
    }


randomEventColors : RollColors decorative msg
randomEventColors =
    { background = Background.color (Element.rgb255 251 233 231)
    , header = textAndBackground (Color.rgb255 191 54 12)
    }


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


gray : Palette -> Color.Color
gray palette =
    palette.surface
        |> MaterialColor.withShade palette.on.surface 0.5
