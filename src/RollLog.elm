module RollLog exposing (rollFateChart, rollMeaningTable, rollRandomEvent)

import Adventure exposing (Character, PlayerCharacter, RollLogEntry(..), Thread)
import ChaosFactor exposing (ChaosFactor)
import FateChart
import Maybe.Extra as MaybeX
import Random
import Random.List
import RandomEvent exposing (RandomEventFocus)
import Task
import Utils exposing (randomToTask, timestamp)


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


rollMeaningTable : String -> Task.Task Never RollLogEntry
rollMeaningTable table =
    let
        subTables : List String
        subTables =
            case table of
                "actions" ->
                    [ "actions_1", "actions_2" ]

                "descriptions" ->
                    [ "descriptions_1", "descriptions_2" ]

                _ ->
                    [ table, table ]
    in
    Task.map2
        (\ts rolls ->
            MeaningTableRollEntry
                { table = table
                , results = rolls |> List.map2 (\subTable value -> { table = subTable, value = value }) subTables
                , timestamp = ts
                }
        )
        timestamp
        (randomToTask meaningTableRolls)


meaningTableRolls : Random.Generator (List Int)
meaningTableRolls =
    Random.map2 (\roll1 roll2 -> [ roll1, roll2 ]) roll100Die roll100Die


rollRandomEvent : List Character -> List Thread -> List PlayerCharacter -> Task.Task Never RollLogEntry
rollRandomEvent characters threads players =
    Task.map2
        (\ts roll ->
            let
                focus : RandomEventFocus
                focus =
                    if roll.value <= 5 then
                        RandomEvent.RemoteEvent

                    else if roll.value <= 10 then
                        RandomEvent.AmbiguousEvent

                    else if roll.value <= 20 then
                        RandomEvent.NewNpc

                    else if roll.value <= 40 then
                        roll.character |> MaybeX.unwrap RandomEvent.CurrentContext (\x -> RandomEvent.NpcEvent "NPC Action" x.name)

                    else if roll.value <= 45 then
                        roll.character |> MaybeX.unwrap RandomEvent.CurrentContext (\x -> RandomEvent.NpcEvent "NPC negative" x.name)

                    else if roll.value <= 50 then
                        roll.character |> MaybeX.unwrap RandomEvent.CurrentContext (\x -> RandomEvent.NpcEvent "NPC Positive" x.name)

                    else if roll.value <= 55 then
                        roll.thread |> MaybeX.unwrap RandomEvent.CurrentContext (\x -> RandomEvent.ThreadEvent "Move toward a Thread" x.name)

                    else if roll.value <= 65 then
                        roll.thread |> MaybeX.unwrap RandomEvent.CurrentContext (\x -> RandomEvent.ThreadEvent "Move away from a Thread" x.name)

                    else if roll.value <= 70 then
                        roll.thread |> MaybeX.unwrap RandomEvent.CurrentContext (\x -> RandomEvent.ThreadEvent "Close a Thread" x.name)

                    else if roll.value <= 80 then
                        RandomEvent.PcEvent "PC Positive" (roll.player |> Maybe.map .name)

                    else if roll.value <= 85 then
                        RandomEvent.PcEvent "PC Negative" (roll.player |> Maybe.map .name)

                    else
                        RandomEvent.CurrentContext
            in
            RandomEventRollEntry
                { focus = focus
                , value = roll.value
                , timestamp = ts
                }
        )
        timestamp
        (randomToTask (randomEventRollsGenerator characters threads players))


randomEventRollsGenerator :
    List Character
    -> List Thread
    -> List PlayerCharacter
    ->
        Random.Generator
            { value : Int
            , character : Maybe Character
            , thread : Maybe Thread
            , player : Maybe PlayerCharacter
            }
randomEventRollsGenerator characters threads players =
    Random.map4
        (\value character thread player ->
            { value = value
            , character = character
            , thread = thread
            , player = player
            }
        )
        roll100Die
        (rollCharacter characters)
        (rollThread threads)
        (rollPlayerCharacter players)


rollCharacter : List Character -> Random.Generator (Maybe Character)
rollCharacter characters =
    Random.List.choose characters |> Random.map (\( character, _ ) -> character)


rollThread : List Thread -> Random.Generator (Maybe Thread)
rollThread threads =
    Random.List.choose threads |> Random.map (\( thread, _ ) -> thread)


rollPlayerCharacter : List PlayerCharacter -> Random.Generator (Maybe PlayerCharacter)
rollPlayerCharacter players =
    Random.List.choose players |> Random.map (\( player, _ ) -> player)


roll100Die : Random.Generator Int
roll100Die =
    Random.int 1 100
