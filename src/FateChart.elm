module FateChart exposing 
  ( FateChart, Probability, Outcome
  , rollFateChart
  , fateChartStandard
  )

import Random
import List.Extra as XList

type alias FateChart = List ChaosFactor

type alias ChaosFactor = 
  { min : Int
  , max : Int
  , outcomeProbabilities : List OutcomeProbability
  }

type alias OutcomeProbability =
  { probability : Probability
  , extremeYes : Int
  , threshold : Int
  , extremeNo : Int
  }


type Probability
  = Certain
  | NearlyCertain


type Outcome
  = Yes
  | ExtremeYes
  | No
  | ExtremeNo

-- rollFateChart : Probability -> Int -> Outcome
-- rollFateChart probability chaosFactor = Yes

rollFateChart : FateChart -> Probability -> Int -> Random.Generator Outcome
rollFateChart chart probability chaosFactor =
  let
    outcomeProbability = XList.find (\x -> chaosFactor >= x.min && chaosFactor <= x.max) chart
      |> Maybe.withDefault defaultChaosFactor
      |> .outcomeProbabilities
      |> XList.find (\x -> probability == x.probability)
      |> Maybe.withDefault defaultOutcomeProbability
  in
    Random.map (determineOutcome outcomeProbability) rollDie


determineOutcome: OutcomeProbability -> Int -> Outcome
determineOutcome outcomeProbability dieRoll =
  if dieRoll <= outcomeProbability.extremeYes then
    ExtremeYes
  else if dieRoll <= outcomeProbability.threshold then
    Yes
  else if dieRoll < outcomeProbability.extremeNo then
    No
  else
    ExtremeNo

rollDie : Random.Generator Int
rollDie = Random.int 1 100


fateChartStandard : FateChart
fateChartStandard = 
  [ ChaosFactor 1 1
    [ OutcomeProbability Certain 10 50 91
    , OutcomeProbability NearlyCertain 10 50 91
    ]
  , ChaosFactor 2 2
    [ OutcomeProbability Certain 10 50 91
    , OutcomeProbability NearlyCertain 10 50 91
    ]
  ]

defaultChaosFactor : ChaosFactor
defaultChaosFactor = ChaosFactor 1 1
  [ OutcomeProbability Certain 10 50 91
  , OutcomeProbability NearlyCertain 10 50 91
  ]

defaultOutcomeProbability : OutcomeProbability
defaultOutcomeProbability = OutcomeProbability Certain 10 50 91

-- fateChartMid : FateChart

-- fateChartLow : FateChart

-- fateChartNone : FateChart
