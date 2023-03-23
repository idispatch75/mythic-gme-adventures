module ChaosFactor exposing 
  ( ChaosFactor
  , toInt
  )

type ChaosFactor
  = ChaosFactor Int

toInt : ChaosFactor -> Int
toInt (ChaosFactor int) =
  int
