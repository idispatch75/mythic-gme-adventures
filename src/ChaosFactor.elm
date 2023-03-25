module ChaosFactor exposing
    ( ChaosFactor(..)
    , codec
    , toInt
    )

import Serialize


type ChaosFactor
    = ChaosFactor Int


toInt : ChaosFactor -> Int
toInt (ChaosFactor int) =
    int


codec : Serialize.Codec e ChaosFactor
codec =
    Serialize.int |> Serialize.map ChaosFactor (\(ChaosFactor chaosFactor) -> chaosFactor)
