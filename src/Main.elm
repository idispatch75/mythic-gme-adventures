module Main exposing (main)

import Adventure exposing (Adventure, AdventureId(..))
import Browser exposing (Document)
import ChaosFactor exposing (ChaosFactor(..))
import Dropbox
import FateChart
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Html.Extra as HtmlX
import I18Next exposing (Translations)
import Json.Decode
import Json.Encode
import LocalStorage
import Task
import TaskPort
import Url exposing (Url)



-- MAIN


main : Program () Model (Dropbox.Msg Msg)
main =
    Dropbox.application
        { init = \_ location -> ( init location, Cmd.none )
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        , onAuth = DropboxAuthResponseReceived
        }



-- MODEL


type alias Model =
    { adventure : Maybe Adventure
    , adventures : List Adventure
    , globalSettings : GlobalSettings
    , translations : List Translations
    , error : Maybe String
    , location : Url
    , dropboxInfo : Maybe DropboxInfo
    }


type alias DropboxInfo =
    { userAuth : Dropbox.UserAuth
    }


type GlobalSettingsVersions
    = GlobalSettings_v1 GlobalSettings


type alias GlobalSettings =
    { fateChartType : FateChart.Type
    , saveTimestamp : Int
    }


init : Url -> Model
init location =
    { adventure = Nothing
    , adventures = []
    , globalSettings =
        { fateChartType = FateChart.Standard
        , saveTimestamp = 0
        }
    , translations = []
    , error = Nothing
    , location = location
    , dropboxInfo = Nothing
    }



-- UPDATE


type Msg
    = SaveData
    | DataSaved (Result TaskPort.Error ())
    | LoadData
    | DataLoaded (Result StorageError ( LocalStorage.Key, Adventure ))
    | LoginToDropbox
    | DropboxAuthResponseReceived Dropbox.AuthorizeResult


update : Msg -> Model -> ( Model, Cmd Msg )
update msg orgModel =
    let
        model : Model
        model =
            { orgModel | error = Nothing }
    in
    case msg of
        SaveData ->
            ( model, saveData model )

        DataSaved result ->
            case result of
                Err error ->
                    ( { model | error = Just (TaskPort.errorToString error) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        LoadData ->
            ( model, loadData (AdventureId 1) )

        DataLoaded result ->
            case result of
                Ok ( _, adventure ) ->
                    ( { model | adventure = Just adventure }, Cmd.none )

                Err error ->
                    let
                        errorMessage =
                            case error of
                                NotFound key ->
                                    "NotFound: " ++ key

                                JsonError err ->
                                    "JsonError: " ++ Json.Decode.errorToString err

                                SerializationError ->
                                    "FormatError"

                                InteropError err ->
                                    "InteropError: " ++ TaskPort.errorToString err
                    in
                    ( { model | error = Just errorMessage }, Cmd.none )

        LoginToDropbox ->
            ( model
            , Dropbox.authorize
                { clientId = dropboxAppKey
                , state = Nothing
                , requireRole = Nothing
                , forceReapprove = False
                , disableSignup = False
                , locale = Nothing
                , forceReauthentication = False
                }
                model.location
            )

        DropboxAuthResponseReceived (Dropbox.AuthorizeOk auth) ->
            ( { model | dropboxInfo = Just { userAuth = auth.userAuth } }
            , Cmd.none
            )

        DropboxAuthResponseReceived (Dropbox.DropboxAuthorizeErr error) ->
            Debug.todo "branch 'DropboxAuthResponseReceived (DropboxAuthorizeErr _)' not implemented"

        DropboxAuthResponseReceived (Dropbox.UnknownAccessTokenErr error) ->
            Debug.todo "branch 'DropboxAuthResponseReceived (UnknownAccessTokenErr _)' not implemented"



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Mythic GME Adventures"
    , body =
        [ div []
            [ button [ onClick SaveData ] [ text "Save" ]
            , button [ onClick LoadData ] [ text "Load" ]
            , button [ onClick LoginToDropbox ] [ text "Login" ]
            , div [] [ HtmlX.viewMaybe viewAdventure model.adventure ]
            , div [] [ text (Url.toString model.location) ]
            , div []
                [ model.dropboxInfo
                    |> Maybe.map (\_ -> "Login OK")
                    |> HtmlX.viewMaybe (\res -> text res)
                ]
            ]
        ]
    }


viewAdventure : Adventure -> Html Msg
viewAdventure adventure =
    text adventure.name


dropboxAppKey : String
dropboxAppKey =
    "9bebip9kkxmuo6g"


saveData : Model -> Cmd Msg
saveData model =
    let
        adventure : Adventure
        adventure =
            Maybe.withDefault defaultAdventure model.adventure

        serialized : Json.Encode.Value
        serialized =
            Adventure.serialize adventure
    in
    putJson (adventureStorageKey adventure.id) serialized
        |> Task.attempt DataSaved


loadData : AdventureId -> Cmd Msg
loadData adventureId =
    let
        key : LocalStorage.Key
        key =
            adventureStorageKey adventureId
    in
    getJson key
        |> Task.andThen
            (\jsonValue ->
                case Adventure.deserialize jsonValue of
                    Ok value ->
                        Task.succeed value

                    Err _ ->
                        Task.fail SerializationError
            )
        |> Task.attempt (\result -> DataLoaded (Result.map (\adventure -> ( key, adventure )) result))


putJson : LocalStorage.Key -> Json.Encode.Value -> TaskPort.Task ()
putJson key jsonValue =
    LocalStorage.localPut key (Json.Encode.encode 0 jsonValue)


adventureStorageKey : AdventureId -> LocalStorage.Key
adventureStorageKey id =
    "adventures/" ++ String.fromInt (Adventure.adventureIdToInt id)


type StorageError
    = NotFound LocalStorage.Key
    | JsonError Json.Decode.Error
    | SerializationError
    | InteropError TaskPort.Error


getJson : LocalStorage.Key -> Task.Task StorageError Json.Decode.Value
getJson key =
    LocalStorage.localGet key
        |> Task.onError (\error -> Task.fail (InteropError error))
        |> Task.andThen
            (\maybeStringValue ->
                case maybeStringValue of
                    Just stringValue ->
                        case Json.Decode.decodeString Json.Decode.value stringValue of
                            Ok value ->
                                Task.succeed value

                            Err error ->
                                Task.fail (JsonError error)

                    Nothing ->
                        Task.fail (NotFound key)
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
    , saveTimestamp = 0
    }
