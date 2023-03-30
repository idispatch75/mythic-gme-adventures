module ChaosFactor exposing
    ( ChaosFactor
    , codec
    , fromInt
    , toInt
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


codec : Serialize.Codec e ChaosFactor
codec =
    Serialize.int |> Serialize.map ChaosFactor (\(ChaosFactor chaosFactor) -> chaosFactor)
