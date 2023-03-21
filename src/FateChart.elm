module FateChart exposing 
  ( Type, Probability, Outcome
  , rollFateChart
  )

import Random
import List.Extra as ListX


type Type
  = Standard
  | Mid
  | Low
  | None


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
  = ExtremeYes
  | Yes
  | No
  | ExtremeNo


rollFateChart : Type -> Probability -> Int -> Random.Generator Outcome
rollFateChart chartType probability chaosFactor =
  Random.map (determineOutcome chartType probability chaosFactor) rollDie


determineOutcome: Type -> Probability -> Int -> Int -> Outcome
determineOutcome chartType probability chaosFactor dieRoll =
  let
    outcomeProbability = ListX.find (\x -> chaosFactor >= x.min && chaosFactor <= x.max) (chartFromType chartType)
      |> Maybe.withDefault defaultChaosFactor
      |> .outcomeProbabilities
      |> ListX.find (\x -> probability == x.probability)
      |> Maybe.withDefault defaultOutcomeProbability
  in
    if dieRoll <= outcomeProbability.extremeYes then
      ExtremeYes
    else if dieRoll <= outcomeProbability.threshold then
      Yes
    else if dieRoll < outcomeProbability.extremeNo then
      No
    else
      ExtremeNo


chartFromType : Type -> FateChart
chartFromType chartType = 
  case chartType of
    Standard -> fateChartStandard
    Mid -> fateChartMid
    Low -> fateChartLow
    None -> fateChartNone


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


fateChartMid : FateChart
fateChartMid = []


fateChartLow : FateChart
fateChartLow = []


fateChartNone : FateChart
fateChartNone = []


defaultChaosFactor : ChaosFactor
defaultChaosFactor = ChaosFactor 1 1
  [ OutcomeProbability Certain 10 50 91
  , OutcomeProbability NearlyCertain 10 50 91
  ]


defaultOutcomeProbability : OutcomeProbability
defaultOutcomeProbability = OutcomeProbability Certain 10 50 91
