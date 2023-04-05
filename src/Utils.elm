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
