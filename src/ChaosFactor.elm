module ChaosFactor exposing
    ( ChaosFactor
    , codec
    , fromInt
    , offset
    , toInt
    , toString
    )

import Basics.Extra as BasicX
import Serialize


type ChaosFactor
    = ChaosFactor Int


toInt : ChaosFactor -> Int
toInt (ChaosFactor int) =
    int


fromInt : Int -> ChaosFactor
fromInt int =
    ChaosFactor (int |> BasicX.atLeast 1 |> BasicX.atMost 9)


toString : ChaosFactor -> String
toString (ChaosFactor int) =
    String.fromInt int


offset : Int -> ChaosFactor -> ChaosFactor
offset amount chaosFactor =
    fromInt (toInt chaosFactor + amount)


codec : Serialize.Codec e ChaosFactor
codec =
    Serialize.int |> Serialize.map ChaosFactor (\(ChaosFactor chaosFactor) -> chaosFactor)
