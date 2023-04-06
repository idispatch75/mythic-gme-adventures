module Utils exposing (..)

import Element exposing (Attribute)
import Html.Attributes
import Random
import Task exposing (Task)
import Time


timestamp : Task Never Int
timestamp =
    Time.now
        |> Task.map (\now -> Time.posixToMillis now)


randomToTask : Random.Generator a -> Task Never a
randomToTask generator =
    Time.now
        |> Task.map (Tuple.first << Random.step generator << Random.initialSeed << Time.posixToMillis)


maxHeightVh : Int -> Attribute msg
maxHeightVh height =
    Element.htmlAttribute (Html.Attributes.style "max-height" (String.fromInt height ++ "vh"))


heightVh : Int -> Attribute msg
heightVh height =
    Element.htmlAttribute (Html.Attributes.style "height" (String.fromInt height ++ "vh"))


heightPercent : Int -> Attribute msg
heightPercent height =
    Element.htmlAttribute (Html.Attributes.style "height" (String.fromInt height ++ "%"))
