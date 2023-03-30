module GlobalSettings exposing (GlobalSettings, deserialize, serialize)

import Adventure exposing (AdventureId)
import FateChart
import Json.Encode exposing (Value)
import Serialize


type alias GlobalSettings =
    { fateChartType : FateChart.Type
    , latestAdventureId : Maybe AdventureId
    , saveTimestamp : Int
    }


globalSettingsCodec : Serialize.Codec e GlobalSettings
globalSettingsCodec =
    Serialize.record GlobalSettings
        |> Serialize.field .fateChartType FateChart.typeCodec
        |> Serialize.field .latestAdventureId (Serialize.maybe Adventure.adventureIdCodec)
        |> Serialize.field .saveTimestamp Serialize.int
        |> Serialize.finishRecord


serialize : GlobalSettings -> Value
serialize adventure =
    Serialize.encodeToJson versionCodec adventure


deserialize : Value -> Result (Serialize.Error e) GlobalSettings
deserialize value =
    Serialize.decodeFromJson versionCodec value


type GlobalSettingsVersions
    = GlobalSettings_v1 GlobalSettings


versionCodec : Serialize.Codec e GlobalSettings
versionCodec =
    Serialize.customType
        (\v1Encoder value ->
            case value of
                GlobalSettings_v1 settings ->
                    v1Encoder settings
        )
        |> Serialize.variant1 GlobalSettings_v1 globalSettingsCodec
        |> Serialize.finishCustomType
        |> Serialize.map
            (\value ->
                case value of
                    GlobalSettings_v1 settings ->
                        settings
            )
            (\value -> GlobalSettings_v1 value)
