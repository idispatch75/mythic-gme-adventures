module FateChart exposing 
  ( Type, Probability, Outcome
  , rollFateChart
  )

import Random
import List.Extra as ListX
import Dict exposing (Dict)
import ChaosFactor exposing (ChaosFactor)


type Type
  = Standard
  | Mid
  | Low
  | None


type alias FateChart = List ChaosFactorOutcomeProbabilities


type alias ChaosFactorOutcomeProbabilities = 
  { min : Int
  , max : Int
  , outcomeProbabilities : List OutcomeProbability
  }


type alias OutcomeProbability =
  { extremeYes : Int
  , threshold : Int
  , extremeNo : Int
  }


type Probability
  = Certain
  | NearlyCertain
  | VeryLikely
  | Likely
  | FiftyFifty
  | Unlikely
  | VeryUnlikely
  | NearlyImpossible
  | Impossible


type Outcome
  = ExtremeYes
  | Yes
  | No
  | ExtremeNo


{-| Returns an Outcome generator for a probability on a chart type. -}
rollFateChart : Type -> Probability -> ChaosFactor -> Random.Generator Outcome
rollFateChart chartType probability chaosFactor =
  Random.map (determineOutcome chartType probability chaosFactor) rollDie


{-| Returns an Outcome generator for a probability on a chart type. -}
determineOutcome : Type -> Probability -> ChaosFactor -> Int -> Outcome
determineOutcome chartType probability chaosFactor dieRoll =
  let
    chaosFactorInt = ChaosFactor.toInt chaosFactor
    outcomeProbability = ListX.find (\x -> chaosFactorInt >= x.min && chaosFactorInt <= x.max) (chartFromType chartType)
      |> Maybe.withDefault fallbackChaosFactor
      |> .outcomeProbabilities
      |> ListX.getAt (probabilityToIndex probability)
      |> Maybe.withDefault fallbackOutcomeProbability
  in
    if dieRoll <= outcomeProbability.extremeYes then
      ExtremeYes
    else if dieRoll <= outcomeProbability.threshold then
      Yes
    else if dieRoll < outcomeProbability.extremeNo then
      No
    else
      ExtremeNo


{-| Determines the index of a Probability in a ChaosFactor.outcomeProbabilities -}
probabilityToIndex : Probability -> Int
probabilityToIndex probability =
  case probability of
    Certain -> 0
    NearlyCertain -> 1
    VeryLikely -> 2
    Likely -> 3
    FiftyFifty -> 4
    Unlikely -> 5
    VeryUnlikely -> 6
    NearlyImpossible -> 7
    Impossible -> 8


{-| Determines the chart to use based on its type -}
chartFromType : Type -> FateChart
chartFromType chartType = 
  case chartType of
    Standard -> fateChartStandard
    Mid -> fateChartMid
    Low -> fateChartLow
    None -> fateChartNone


{-| Returns a generator for a fate die roll -}
rollDie : Random.Generator Int
rollDie = Random.int 1 100


fallbackChaosFactor : ChaosFactorOutcomeProbabilities
fallbackChaosFactor = ChaosFactorOutcomeProbabilities 1 9
  [ outcomeProbability 90
  , outcomeProbability 85
  , outcomeProbability 75
  , outcomeProbability 65
  , outcomeProbability 50
  , outcomeProbability 35
  , outcomeProbability 25
  , outcomeProbability 15
  , outcomeProbability 10
  ]


fallbackOutcomeProbability : OutcomeProbability
fallbackOutcomeProbability = 
  Dict.get 50 availableOutcomeProbabilities 
    |> Maybe.withDefault (OutcomeProbability 10 50 91)


{-| Returns the OutcomeProbability with the specified threshold. -}
outcomeProbability : Int -> OutcomeProbability
outcomeProbability threshold =
  Dict.get threshold availableOutcomeProbabilities 
    |> Maybe.withDefault fallbackOutcomeProbability


{-| The OutcomeProbabilities by threshold. -}
availableOutcomeProbabilities : Dict Int OutcomeProbability
availableOutcomeProbabilities =
  [5, 10, 15, 25, 35, 50, 65, 75, 85, 90, 95]
    |> List.map (\i -> (i, computeOutcomeProbability i))
    |> Dict.fromList
    |> Dict.insert 1 (OutcomeProbability 0 1 81)
    |> Dict.insert 99 (OutcomeProbability 20 99 101)


{-| Computes the OutcomeProbability for a threshold. -}
computeOutcomeProbability : Int -> OutcomeProbability
computeOutcomeProbability threshold =
  let
    extremeYes = threshold * 20 // 100
    extremeNo = 100 - ((100 - threshold) * 20 // 100) + 1
  in
    OutcomeProbability extremeYes threshold extremeNo


fateChartStandard : FateChart
fateChartStandard = 
  [ ChaosFactorOutcomeProbabilities 1 1
    [ outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    , outcomeProbability 15
    , outcomeProbability 10
    , outcomeProbability 5
    , outcomeProbability 1
    , outcomeProbability 1
    , outcomeProbability 1
    ]
  , ChaosFactorOutcomeProbabilities 2 2
    [ outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    , outcomeProbability 15
    , outcomeProbability 10
    , outcomeProbability 5
    , outcomeProbability 1
    , outcomeProbability 1
    ]
  , ChaosFactorOutcomeProbabilities 3 3
    [ outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    , outcomeProbability 15
    , outcomeProbability 10
    , outcomeProbability 5
    , outcomeProbability 1
    ]
  , ChaosFactorOutcomeProbabilities 4 4
    [ outcomeProbability 85
    , outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    , outcomeProbability 15
    , outcomeProbability 10
    , outcomeProbability 5
    ]
  , ChaosFactorOutcomeProbabilities 5 5
    [ outcomeProbability 90
    , outcomeProbability 85
    , outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    , outcomeProbability 15
    , outcomeProbability 10
    ]
  , ChaosFactorOutcomeProbabilities 6 6
    [ outcomeProbability 95
    , outcomeProbability 90
    , outcomeProbability 85
    , outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    , outcomeProbability 15
    ]
  , ChaosFactorOutcomeProbabilities 7 7
    [ outcomeProbability 99
    , outcomeProbability 95
    , outcomeProbability 90
    , outcomeProbability 85
    , outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    , outcomeProbability 25
    ]
  , ChaosFactorOutcomeProbabilities 8 8
    [ outcomeProbability 99
    , outcomeProbability 99
    , outcomeProbability 95
    , outcomeProbability 90
    , outcomeProbability 85
    , outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    , outcomeProbability 35
    ]
  , ChaosFactorOutcomeProbabilities 9 9
    [ outcomeProbability 99
    , outcomeProbability 99
    , outcomeProbability 99
    , outcomeProbability 95
    , outcomeProbability 90
    , outcomeProbability 85
    , outcomeProbability 75
    , outcomeProbability 65
    , outcomeProbability 50
    ]
  ]


fateChartMid : FateChart
fateChartMid = 
  [ buildChaosFactorFromChart 1 1 2 fateChartStandard
  , buildChaosFactorFromChart 2 3 3 fateChartStandard
  , buildChaosFactorFromChart 4 6 4 fateChartStandard
  , buildChaosFactorFromChart 7 8 5 fateChartStandard
  , buildChaosFactorFromChart 9 9 6 fateChartStandard
  ]


fateChartLow : FateChart
fateChartLow = 
  [ buildChaosFactorFromChart 1 2 3 fateChartStandard
  , buildChaosFactorFromChart 3 7 4 fateChartStandard
  , buildChaosFactorFromChart 8 9 5 fateChartStandard
  ]


fateChartNone : FateChart
fateChartNone = 
  [ buildChaosFactorFromChart 1 9 4 fateChartStandard
  ]


{-| Creates a ChaosFactor based on the outcomeProbabilities of the chaos factor at the specified index in a chart. -}
buildChaosFactorFromChart : Int -> Int -> Int -> FateChart -> ChaosFactorOutcomeProbabilities
buildChaosFactorFromChart min max index chart =
  let
    probabilities = ListX.getAt index chart
      |> Maybe.withDefault fallbackChaosFactor
      |> .outcomeProbabilities
  in
    ChaosFactorOutcomeProbabilities min max probabilities
