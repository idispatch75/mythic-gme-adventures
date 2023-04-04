module RollLog exposing (FateChartRoll, RollLogEntry(..), rollFateChart, rollLogEntryCodec)

import ChaosFactor exposing (ChaosFactor)
import FateChart
import Serialize
import Task
import Utils exposing (randomToTask, timestamp)


type RollLogEntry
    = FateChartRollEntry FateChartRoll


type alias FateChartRoll =
    { probability : FateChart.Probability
    , chaosFactor : ChaosFactor
    , value : Int
    , outcome : FateChart.Outcome
    , timestamp : Int
    }


fateChartRollCodec : Serialize.Codec e FateChartRoll
fateChartRollCodec =
    Serialize.record FateChartRoll
        |> Serialize.field .probability FateChart.probabiltyCodec
        |> Serialize.field .chaosFactor ChaosFactor.codec
        |> Serialize.field .value Serialize.int
        |> Serialize.field .outcome FateChart.outcomeCodec
        |> Serialize.field .timestamp Serialize.int
        |> Serialize.finishRecord


rollLogEntryCodec : Serialize.Codec e RollLogEntry
rollLogEntryCodec =
    Serialize.customType
        (\fateChartEncoder value ->
            case value of
                FateChartRollEntry roll ->
                    fateChartEncoder roll
        )
        |> Serialize.variant1 FateChartRollEntry fateChartRollCodec
        |> Serialize.finishCustomType


rollFateChart : FateChart.Type -> FateChart.Probability -> ChaosFactor -> Task.Task Never RollLogEntry
rollFateChart chartType probability chaosFactor =
    Task.map2
        (\ts ( value, outcome ) ->
            FateChartRollEntry
                { probability = probability
                , chaosFactor = chaosFactor
                , value = value
                , outcome = outcome
                , timestamp = ts
                }
        )
        timestamp
        (randomToTask (FateChart.rollFateChart chartType probability chaosFactor))
