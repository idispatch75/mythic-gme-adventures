module ChaosFactor exposing 
    ( ChaosFactor(..)
    , toInt, codec
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
