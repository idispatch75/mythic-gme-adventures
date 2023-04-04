module Utils exposing (..)

import Random
import Task
import Time


timestamp : Task.Task Never Int
timestamp =
    Time.now
        |> Task.map (\now -> Time.posixToMillis now)


randomToTask : Random.Generator a -> Task.Task Never a
randomToTask generator =
    Time.now
        |> Task.map (Tuple.first << Random.step generator << Random.initialSeed << Time.posixToMillis)
