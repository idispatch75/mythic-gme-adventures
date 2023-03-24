module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import FateChart
import I18Next exposing (Translations)
import Adventure exposing (Adventure, AdventureId(..))
import TaskPort
import LocalStorage
import Json.Encode
import TaskPort
import ChaosFactor exposing (ChaosFactor(..))
import Task
import Browser exposing (Document)
import Json.Decode
import Html.Extra as HtmlX



-- MAIN


main : Program () Model Msg
main =
    Browser.document 
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }

-- MODEL


type alias Model2 = Int

type alias Model =
    { adventure : Maybe Adventure
    , adventures : List Adventure
    , globalSettings : GlobalSettings
    , translations : List Translations
    , error : Maybe String
    }


type GlobalSettingsVersions
    = V1 GlobalSettings

type alias GlobalSettings =
    { fateChartType : FateChart.Type
    , adventureNextId : Int
    }


init : () -> (Model, Cmd Msg)
init _ = (
    { adventure = Nothing
    , adventures = []
    , globalSettings = 
        { fateChartType = FateChart.Standard
        , adventureNextId = 1
        }
    , translations = []
    , error = Nothing
    }
    , Cmd.none)

-- UPDATE


type Msg
    = SaveData
    | DataSaved (Result TaskPort.Error ())
    | LoadData
    | DataLoaded (Result StorageError (LocalStorage.Key, Adventure)) 


update : Msg -> Model -> (Model, Cmd Msg)
update msg orgModel =
    let
        model = { orgModel | error = Nothing }
    in
    case msg of
        SaveData ->
            (model, saveData model)

        DataSaved result ->
            case result of
                Err error -> 
                    ({ model | error = Just (TaskPort.errorToString error)}, Cmd.none)

                _ ->
                    (model, Cmd.none)

        LoadData ->
            (model, loadData (AdventureId 1))

        DataLoaded result ->
            case result of
                Ok (_, adventure) -> ({model | adventure = Just adventure}, Cmd.none)

                Err error ->
                    let
                        errorMessage = case error of
                            NotFound key -> "NotFound: " ++ key
                            JsonError err -> "JsonError: " ++ Json.Decode.errorToString err
                            FormatError -> "FormatError"
                            InteropError err -> "InteropError: " ++ TaskPort.errorToString err
                            
                    in
                    ({ model | error = Just errorMessage}, Cmd.none)


-- VIEW


view : Model -> Document Msg
view model =
    { title = "Mythic GME Adventures"
    , body = 
        [ div []
            [ button [ onClick SaveData ] [ text "Save" ]
            , button [ onClick LoadData ] [ text "Load" ]
            , div [] [ viewAdventure model.adventure ]
            ]
        ]
    }

viewAdventure : Maybe Adventure -> Html Msg
viewAdventure maybeAdventure =
    case maybeAdventure of
        Just adventure -> text adventure.name
        Nothing -> HtmlX.nothing

saveData : Model -> Cmd Msg
saveData model =
    let
        adventure = Maybe.withDefault defaultAdventure model.adventure
        serialized = Adventure.serialize adventure
    in
    putJson (adventureStorageKey adventure.id) serialized
        |> Task.attempt DataSaved


loadData : AdventureId -> Cmd Msg
loadData adventureId =
    let
        key = adventureStorageKey adventureId
    in
    getJson key
        |> Task.andThen (\jsonValue ->
            case Adventure.deserialize jsonValue of
                Ok value -> Task.succeed value
                Err _ -> Task.fail FormatError
        )
        |> Task.attempt (\result -> DataLoaded (Result.map (\adventure -> (key, adventure)) result))
        

putJson : LocalStorage.Key -> Json.Encode.Value -> TaskPort.Task ()
putJson key jsonValue = LocalStorage.localPut key (Json.Encode.encode 0 jsonValue)


adventureStorageKey : AdventureId -> LocalStorage.Key
adventureStorageKey id = "adventure_" ++ (String.fromInt (Adventure.adventureIdToInt id))

type StorageError
    = NotFound LocalStorage.Key
    | JsonError Json.Decode.Error
    | FormatError
    | InteropError TaskPort.Error




getJson : LocalStorage.Key -> Task.Task StorageError Json.Decode.Value
getJson key = LocalStorage.localGet key
    |> Task.onError (\error -> Task.fail (InteropError error))
    |> Task.andThen (\maybeStringValue ->
        case maybeStringValue of
            Just stringValue ->
                case (Json.Decode.decodeString Json.Decode.value stringValue) of
                    Ok value -> Task.succeed value
                    Err error -> Task.fail (JsonError error)
            Nothing -> Task.fail (NotFound key)
        )


defaultAdventure : Adventure
defaultAdventure =
    { id = AdventureId 1
    , name = "default"
    , chaosFactor = ChaosFactor 5
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
    }
