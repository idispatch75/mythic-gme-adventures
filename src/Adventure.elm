module Adventure exposing 
    ( Adventure, AdventureId(..)
    , serialize, deserialize
    , adventureIdToInt
    )

import FateChart
import Serialize
import ChaosFactor exposing (ChaosFactor)
import Json.Encode exposing (Value)


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
        |> Serialize.finishRecord


type AdventureId 
    = AdventureId Int


adventureIdToInt : AdventureId -> Int
adventureIdToInt (AdventureId int) =
    int

adventureIdCodec : Serialize.Codec e AdventureId
adventureIdCodec =
    Serialize.int |> Serialize.map AdventureId (\(AdventureId id) -> id)


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
testExpectedScene chaosFactor = Expected


rollSceneAdjustment : List String
rollSceneAdjustment = [ "Remove A Character" ]

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


type alias RollLogEntry =
    { table : Maybe String
    , results : List RollResult    
    -- actions based on roll
    }


rollLogEntryCodec : Serialize.Codec e RollLogEntry
rollLogEntryCodec =
    Serialize.record RollLogEntry
        |> Serialize.field .table (Serialize.maybe Serialize.string)
        |> Serialize.field .results (Serialize.list rollResultCodec)
        |> Serialize.finishRecord


type alias RollResult =
    { value : Int
    , result : String
    }


rollResultCodec : Serialize.Codec e RollResult
rollResultCodec =
    Serialize.record RollResult
        |> Serialize.field .value Serialize.int
        |> Serialize.field .result Serialize.string
        |> Serialize.finishRecord


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
    = V1 Adventure
    

versionCodec : Serialize.Codec e Adventure
versionCodec =
    Serialize.customType
        (\v1Encoder value ->
            case value of
                V1 adventure ->
                    v1Encoder adventure
        )
        |> Serialize.variant1 V1 adventureCodec
        |> Serialize.finishCustomType
        |> Serialize.map
            (\value ->
                case value of
                    V1 adventure ->
                        adventure
            )
            (\value -> V1 value)
