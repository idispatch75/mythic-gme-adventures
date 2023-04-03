module DataStorage exposing
    ( LoadError(..)
    , SaveError(..)
    , loadAdventure
    , loadLocal
    , saveLocal
    )

import Adventure exposing (Adventure, AdventureId, AdventureIndex)
import GlobalSettings exposing (GlobalSettings)
import Json.Decode exposing (Value)
import Json.Encode
import LocalStorage
import Serialize
import Task exposing (Task)
import TaskPort


type LoadError
    = NotFound LocalStorage.Key
    | SerializationError
    | JsonDecodeError Json.Decode.Error
    | LoadInteropError TaskPort.Error


type SaveError
    = SaveInteropError TaskPort.Error


saveLocal : AdventureIndex -> Maybe Adventure -> GlobalSettings -> Task SaveError ()
saveLocal adventureIndex maybeAdventure settings =
    let
        indexTask : Task SaveError ()
        indexTask =
            saveLocalAdventureIndex adventureIndex

        settingsTask : Task SaveError ()
        settingsTask =
            saveGlobalSettings settings

        adventureTask : Task SaveError ()
        adventureTask =
            maybeAdventure
                |> Maybe.map saveLocalAdventure
                |> Maybe.withDefault (Task.succeed ())
    in
    indexTask
        |> Task.andThen (\_ -> settingsTask)
        |> Task.andThen (\_ -> adventureTask)


{-| Loads the adventure index and the global settings.
-}
loadLocal : Task LoadError ( AdventureIndex, GlobalSettings )
loadLocal =
    Task.map2 (\index settings -> ( index, settings )) loadLocalAdventureIndex loadGlobalSettings


loadAdventure : AdventureId -> Task LoadError Adventure
loadAdventure id =
    loadLocalAdventure id


saveLocalAdventureIndex : AdventureIndex -> Task SaveError ()
saveLocalAdventureIndex index =
    let
        serialized : Json.Encode.Value
        serialized =
            Adventure.serializeIndex index
    in
    putJson adventureIndexStorageKey serialized


loadLocalAdventureIndex : Task LoadError AdventureIndex
loadLocalAdventureIndex =
    deserialize adventureIndexStorageKey Adventure.deserializeIndex


saveGlobalSettings : GlobalSettings -> Task SaveError ()
saveGlobalSettings settings =
    let
        serialized : Json.Encode.Value
        serialized =
            GlobalSettings.serialize settings
    in
    putJson globalSettingsStorageKey serialized


loadGlobalSettings : Task LoadError GlobalSettings
loadGlobalSettings =
    deserialize globalSettingsStorageKey GlobalSettings.deserialize


saveLocalAdventure : Adventure -> Task SaveError ()
saveLocalAdventure adventure =
    let
        serialized : Json.Encode.Value
        serialized =
            Adventure.serialize adventure
    in
    putJson (adventureStorageKey adventure.id) serialized


loadLocalAdventure : AdventureId -> Task LoadError Adventure
loadLocalAdventure adventureId =
    let
        key : LocalStorage.Key
        key =
            adventureStorageKey adventureId
    in
    deserialize key Adventure.deserialize


deserialize : LocalStorage.Key -> (Value -> Result (Serialize.Error e) a) -> Task LoadError a
deserialize key deserializer =
    getJson key
        |> Task.andThen
            (\jsonValue ->
                case deserializer jsonValue of
                    Ok value ->
                        Task.succeed value

                    Err _ ->
                        Task.fail SerializationError
            )


adventureStorageKey : AdventureId -> LocalStorage.Key
adventureStorageKey id =
    "adventures/" ++ String.fromInt (Adventure.adventureIdToInt id)


adventureIndexStorageKey : LocalStorage.Key
adventureIndexStorageKey =
    "adventure-index"


globalSettingsStorageKey : LocalStorage.Key
globalSettingsStorageKey =
    "settings"


getJson : LocalStorage.Key -> Task.Task LoadError Json.Decode.Value
getJson key =
    LocalStorage.localGet key
        |> Task.onError (\error -> Task.fail (LoadInteropError error))
        |> Task.andThen
            (\maybeStringValue ->
                case maybeStringValue of
                    Just stringValue ->
                        case Json.Decode.decodeString Json.Decode.value stringValue of
                            Ok value ->
                                Task.succeed value

                            Err error ->
                                Task.fail (JsonDecodeError error)

                    Nothing ->
                        Task.fail (NotFound key)
            )


putJson : LocalStorage.Key -> Json.Encode.Value -> Task SaveError ()
putJson key jsonValue =
    LocalStorage.localPut key (Json.Encode.encode 0 jsonValue)
        |> Task.onError (\error -> Task.fail (SaveInteropError error))
