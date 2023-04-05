module Adventure exposing
    ( Adventure
    , AdventureId(..)
    , AdventureIndex
    , AdventureNote
    , AdventureSettings
    , Character
    , FateChartRoll
    , IndexAdventure
    , MeaningTableRoll
    , MeaningTableSubRoll
    , PlayerCharacter
    , RandomEventRoll
    , RollLogEntry(..)
    , Scene
    , Thread
    , addAdventure
    , addRollLogEntry
    , adventureIdCodec
    , adventureIdToInt
    , createAdventure
    , createAdventureIndex
    , deserialize
    , deserializeIndex
    , serialize
    , serializeIndex
    )

import ChaosFactor exposing (ChaosFactor)
import FateChart
import Json.Encode exposing (Value)
import RandomEvent exposing (RandomEventFocus)
import Serialize
import Task exposing (Task)
import Time


type alias Adventure =
    { id : AdventureId
    , name : String
    , chaosFactor : ChaosFactor
    , scenes : List Scene
    , threadList : List Int
    , characterList : List CharacterId
    , threads : List Thread
    , characters : List Character
    , playerCharacters : List PlayerCharacter
    , rollLog : List RollLogEntry
    , notes : List AdventureNote
    , settings : AdventureSettings
    , saveTimestamp : Int

    -- TODO thread progress track
    -- TODO keyed scenes
    }


adventureCodec : Serialize.Codec e Adventure
adventureCodec =
    Serialize.record Adventure
        |> Serialize.field .id adventureIdCodec
        |> Serialize.field .name Serialize.string
        |> Serialize.field .chaosFactor ChaosFactor.codec
        |> Serialize.field .scenes (Serialize.list sceneCodec)
        |> Serialize.field .threadList (Serialize.list Serialize.int)
        |> Serialize.field .characterList (Serialize.list characterIdCodec)
        |> Serialize.field .threads (Serialize.list threadCodec)
        |> Serialize.field .characters (Serialize.list characterCodec)
        |> Serialize.field .playerCharacters (Serialize.list playerCharacterCodec)
        |> Serialize.field .rollLog (Serialize.list rollLogEntryCodec)
        |> Serialize.field .notes (Serialize.list adventureNoteCodec)
        |> Serialize.field .settings adventureSettingsCodec
        |> Serialize.field .saveTimestamp Serialize.int
        |> Serialize.finishRecord


type AdventureId
    = AdventureId Int


adventureIdCodec : Serialize.Codec e AdventureId
adventureIdCodec =
    Serialize.int |> Serialize.map AdventureId (\(AdventureId id) -> id)


adventureIdToInt : AdventureId -> Int
adventureIdToInt (AdventureId int) =
    int


createAdventure : Task x Adventure
createAdventure =
    Time.now
        |> Task.map
            (\now ->
                { id = AdventureId (Time.posixToMillis now)
                , name = "New adventure"
                , chaosFactor = ChaosFactor.fromInt 5
                , scenes = []
                , threadList = []
                , characterList = []
                , threads = []
                , characters = []
                , playerCharacters = []
                , rollLog = []
                , notes = []
                , settings =
                    { fateChartType = FateChart.Standard
                    }
                , saveTimestamp = 0
                }
            )


type alias AdventureIndex =
    { adventures : List IndexAdventure
    , saveTimestamp : Int
    }


adventureIndexCodec : Serialize.Codec e AdventureIndex
adventureIndexCodec =
    Serialize.record AdventureIndex
        |> Serialize.field .adventures (Serialize.list indexAdventureCodec)
        |> Serialize.field .saveTimestamp Serialize.int
        |> Serialize.finishRecord


type alias IndexAdventure =
    { id : AdventureId
    , name : String
    }


indexAdventureCodec : Serialize.Codec e IndexAdventure
indexAdventureCodec =
    Serialize.record IndexAdventure
        |> Serialize.field .id adventureIdCodec
        |> Serialize.field .name Serialize.string
        |> Serialize.finishRecord


createAdventureIndex : AdventureIndex
createAdventureIndex =
    { adventures = []
    , saveTimestamp = 0
    }


addAdventure : Adventure -> AdventureIndex -> AdventureIndex
addAdventure adventure index =
    { index | adventures = IndexAdventure adventure.id adventure.name :: index.adventures }


type alias Scene =
    { summary : Maybe String
    , notes : Maybe String
    }


sceneCodec : Serialize.Codec e Scene
sceneCodec =
    Serialize.record Scene
        |> Serialize.field .summary (Serialize.maybe Serialize.string)
        |> Serialize.field .notes (Serialize.maybe Serialize.string)
        |> Serialize.finishRecord


type SceneType
    = Expected
    | Altered
    | Interrupted


testExpectedScene : Int -> SceneType
testExpectedScene chaosFactor =
    Expected


rollSceneAdjustment : List String
rollSceneAdjustment =
    [ "Remove A Character" ]



-- rollPlayerCharacter : Model -> Maybe PlayerCharacter
-- rollPlayerCharacter model =
--     model.adventure
--     |> Maybe.andThen (\x ->  List.head x.playerCharacters) -- TODO


type alias Character =
    { id : CharacterId
    , name : String
    , summary : Maybe String
    , notes : Maybe String
    }


characterCodec : Serialize.Codec e Character
characterCodec =
    Serialize.record Character
        |> Serialize.field .id characterIdCodec
        |> Serialize.field .name Serialize.string
        |> Serialize.field .summary (Serialize.maybe Serialize.string)
        |> Serialize.field .notes (Serialize.maybe Serialize.string)
        |> Serialize.finishRecord


type CharacterId
    = CharacterId Int


characterIdCodec : Serialize.Codec e CharacterId
characterIdCodec =
    Serialize.int |> Serialize.map CharacterId (\(CharacterId id) -> id)



-- characterIdDecoder : Decoder CharacterId
-- characterIdDecoder =
--     Decode.map CharacterId int


type alias PlayerCharacter =
    { name : String
    }


playerCharacterCodec : Serialize.Codec e PlayerCharacter
playerCharacterCodec =
    Serialize.record PlayerCharacter
        |> Serialize.field .name Serialize.string
        |> Serialize.finishRecord


type alias Thread =
    { id : ThreadId
    , name : String
    , notes : Maybe String
    }


threadCodec : Serialize.Codec e Thread
threadCodec =
    Serialize.record Thread
        |> Serialize.field .id threadIdCodec
        |> Serialize.field .name Serialize.string
        |> Serialize.field .notes (Serialize.maybe Serialize.string)
        |> Serialize.finishRecord


type ThreadId
    = ThreadId Int


threadIdCodec : Serialize.Codec e ThreadId
threadIdCodec =
    Serialize.int |> Serialize.map ThreadId (\(ThreadId id) -> id)


type alias AdventureNote =
    { title : Maybe String
    , text : String
    }


adventureNoteCodec : Serialize.Codec e AdventureNote
adventureNoteCodec =
    Serialize.record AdventureNote
        |> Serialize.field .title (Serialize.maybe Serialize.string)
        |> Serialize.field .text Serialize.string
        |> Serialize.finishRecord


type RollLogEntry
    = FateChartRollEntry FateChartRoll
    | MeaningTableRollEntry MeaningTableRoll
    | RandomEventRollEntry RandomEventRoll


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


type alias MeaningTableRoll =
    { table : String
    , results : List MeaningTableSubRoll
    , timestamp : Int
    }


meaningTableRollCodec : Serialize.Codec e MeaningTableRoll
meaningTableRollCodec =
    Serialize.record MeaningTableRoll
        |> Serialize.field .table Serialize.string
        |> Serialize.field .results (Serialize.list meaningTableSubRollCodec)
        |> Serialize.field .timestamp Serialize.int
        |> Serialize.finishRecord


type alias MeaningTableSubRoll =
    { value : Int
    , table : String
    }


meaningTableSubRollCodec : Serialize.Codec e MeaningTableSubRoll
meaningTableSubRollCodec =
    Serialize.record MeaningTableSubRoll
        |> Serialize.field .value Serialize.int
        |> Serialize.field .table Serialize.string
        |> Serialize.finishRecord


type alias RandomEventRoll =
    { focus : RandomEventFocus
    , value : Int
    , timestamp : Int
    }


randomEventRollCodec : Serialize.Codec e RandomEventRoll
randomEventRollCodec =
    Serialize.record RandomEventRoll
        |> Serialize.field .focus RandomEvent.focusCodec
        |> Serialize.field .value Serialize.int
        |> Serialize.field .timestamp Serialize.int
        |> Serialize.finishRecord


rollLogEntryCodec : Serialize.Codec e RollLogEntry
rollLogEntryCodec =
    Serialize.customType
        (\fateChartEncoder meaningTableEncoder randomEventEncoder value ->
            case value of
                FateChartRollEntry roll ->
                    fateChartEncoder roll

                MeaningTableRollEntry roll ->
                    meaningTableEncoder roll

                RandomEventRollEntry roll ->
                    randomEventEncoder roll
        )
        |> Serialize.variant1 FateChartRollEntry fateChartRollCodec
        |> Serialize.variant1 MeaningTableRollEntry meaningTableRollCodec
        |> Serialize.variant1 RandomEventRollEntry randomEventRollCodec
        |> Serialize.finishCustomType


addRollLogEntry : RollLogEntry -> Adventure -> Adventure
addRollLogEntry entry adventure =
    { adventure | rollLog = List.append adventure.rollLog (List.singleton entry) |> List.take 100 }


type alias AdventureSettings =
    { fateChartType : FateChart.Type
    }


adventureSettingsCodec : Serialize.Codec e AdventureSettings
adventureSettingsCodec =
    Serialize.record AdventureSettings
        |> Serialize.field .fateChartType FateChart.typeCodec
        |> Serialize.finishRecord


serialize : Adventure -> Value
serialize adventure =
    Serialize.encodeToJson versionCodec adventure


deserialize : Value -> Result (Serialize.Error e) Adventure
deserialize value =
    Serialize.decodeFromJson versionCodec value


type SerializationVersions
    = Adventure_v1 Adventure


versionCodec : Serialize.Codec e Adventure
versionCodec =
    Serialize.customType
        (\v1Encoder value ->
            case value of
                Adventure_v1 adventure ->
                    v1Encoder adventure
        )
        |> Serialize.variant1 Adventure_v1 adventureCodec
        |> Serialize.finishCustomType
        |> Serialize.map
            (\value ->
                case value of
                    Adventure_v1 adventure ->
                        adventure
            )
            (\value -> Adventure_v1 value)


serializeIndex : AdventureIndex -> Value
serializeIndex index =
    Serialize.encodeToJson indexVersionCodec index


deserializeIndex : Value -> Result (Serialize.Error e) AdventureIndex
deserializeIndex value =
    Serialize.decodeFromJson indexVersionCodec value


type IndexSerializationVersions
    = Index_v1 AdventureIndex


indexVersionCodec : Serialize.Codec e AdventureIndex
indexVersionCodec =
    Serialize.customType
        (\v1Encoder value ->
            case value of
                Index_v1 index ->
                    v1Encoder index
        )
        |> Serialize.variant1 Index_v1 adventureIndexCodec
        |> Serialize.finishCustomType
        |> Serialize.map
            (\value ->
                case value of
                    Index_v1 index ->
                        index
            )
            (\value -> Index_v1 value)
