module FateChart exposing 
  ( Type, Probability, Outcome
  , rollFateChart
  )

import Random
import List.Extra as ListX
import Dict exposing (Dict)


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
rollFateChart : Type -> Probability -> Int -> Random.Generator Outcome
rollFateChart chartType probability chaosFactor =
  Random.map (determineOutcome chartType probability chaosFactor) rollDie


{-| Returns an Outcome generator for a probability on a chart type. -}
determineOutcome : Type -> Probability -> Int -> Int -> Outcome
determineOutcome chartType probability chaosFactor dieRoll =
  let
    outcomeProbability = ListX.find (\x -> chaosFactor >= x.min && chaosFactor <= x.max) (chartFromType chartType)
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


fallbackChaosFactor : ChaosFactor
fallbackChaosFactor = ChaosFactor 1 9
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
fallbackOutcomeProbability = Dict.get 50 outcomeProbabilities |> Maybe.withDefault (OutcomeProbability 10 50 91)


{-| Returns the OutcomeProbability with the specified threshold. -}
outcomeProbability : Int -> OutcomeProbability
outcomeProbability threshold =
  Dict.get threshold outcomeProbabilities |> Maybe.withDefault fallbackOutcomeProbability


{-| The OutcomeProbabilities by threshold. -}
outcomeProbabilities : Dict Int OutcomeProbability
outcomeProbabilities =
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
  [ ChaosFactor 1 1
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
  , ChaosFactor 2 2
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
  , ChaosFactor 3 3
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
  , ChaosFactor 4 4
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
  , ChaosFactor 5 5
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
  , ChaosFactor 6 6
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
  , ChaosFactor 7 7
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
  , ChaosFactor 8 8
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
  , ChaosFactor 9 9
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
  [ buildChaosFactor 1 1 2 fateChartStandard
  , buildChaosFactor 2 3 3 fateChartStandard
  , buildChaosFactor 4 6 4 fateChartStandard
  , buildChaosFactor 7 8 5 fateChartStandard
  , buildChaosFactor 9 9 6 fateChartStandard
  ]


fateChartLow : FateChart
fateChartLow = 
  [ buildChaosFactor 1 2 3 fateChartStandard
  , buildChaosFactor 3 7 4 fateChartStandard
  , buildChaosFactor 8 9 5 fateChartStandard
  ]


fateChartNone : FateChart
fateChartNone = 
  [ buildChaosFactor 1 9 4 fateChartStandard
  ]


{-| Creates a ChaosFactor based on the outcomeProbabilities of the chaos factor at the specified index in a chart. -}
buildChaosFactor : Int -> Int -> Int -> FateChart -> ChaosFactor
buildChaosFactor min max index chart =
  let
    probabilities = ListX.getAt index chart
      |> Maybe.withDefault fallbackChaosFactor
      |> .outcomeProbabilities
  in
    ChaosFactor min max probabilities
