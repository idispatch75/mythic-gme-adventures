module Main exposing (main)

import Adventure exposing (Adventure, AdventureId(..), AdventureIndex, IndexAdventure, createAdventureIndex)
import Browser exposing (Document)
import DataStorage
import Dropbox
import FateChart
import GlobalSettings exposing (GlobalSettings)
import Html exposing (Html, button, div, li, text)
import Html.Events exposing (onClick)
import Html.Extra as HtmlX
import Html.Keyed exposing (ul)
import I18Next exposing (Translations)
import Json.Decode
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
    , adventureIndex : AdventureIndex
    , globalSettings : GlobalSettings
    , translations : List Translations
    , error : Maybe String
    , location : Url
    , dropboxInfo : Maybe DropboxInfo
    }


type alias DropboxInfo =
    { userAuth : Dropbox.UserAuth
    }


init : Url -> Model
init location =
    { adventure = Nothing
    , adventureIndex = createAdventureIndex
    , globalSettings =
        { fateChartType = FateChart.Standard
        , latestAdventureId = Nothing
        , saveTimestamp = 0
        }
    , translations = []
    , error = Nothing
    , location = location
    , dropboxInfo = Nothing
    }



-- UPDATE


type Msg
    = CreateAdventure
    | AdventureCreated Adventure
    | SaveData
    | LocalDataSaved (Result DataStorage.SaveError ())
    | LoadData
    | DataLoaded (Result DataStorage.LoadError ( LocalStorage.Key, Adventure ))
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
        CreateAdventure ->
            ( model, Adventure.createAdventure |> Task.perform (\adventure -> AdventureCreated adventure) )

        AdventureCreated adventure ->
            let
                index : AdventureIndex
                index =
                    Adventure.addAdventure adventure model.adventureIndex
            in
            ( { model
                | adventure = Just adventure
                , adventureIndex = index
              }
            , saveData model
            )

        SaveData ->
            ( model, saveData model )

        LocalDataSaved result ->
            case result of
                Err error ->
                    ( { model | error = Just "Error" }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        LoadData ->
            Debug.todo "branch 'LoadData' not implemented"

        DataLoaded result ->
            case result of
                Ok ( _, adventure ) ->
                    ( { model | adventure = Just adventure }, Cmd.none )

                Err error ->
                    let
                        errorMessage =
                            case error of
                                DataStorage.NotFound key ->
                                    "NotFound: " ++ key

                                DataStorage.JsonDecodeError err ->
                                    "JsonError: " ++ Json.Decode.errorToString err

                                DataStorage.SerializationError ->
                                    "FormatError"

                                DataStorage.LoadInteropError err ->
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
            , button [ onClick CreateAdventure ] [ text "Create adventure" ]
            , div []
                [ ul [] (List.map viewIndexAdventure model.adventureIndex.adventures)
                ]
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


viewIndexAdventure : IndexAdventure -> ( String, Html Msg )
viewIndexAdventure adventure =
    ( String.fromInt (Adventure.adventureIdToInt adventure.id)
    , div []
        [ text adventure.name ]
    )


dropboxAppKey : String
dropboxAppKey =
    "9bebip9kkxmuo6g"


saveData : Model -> Cmd Msg
saveData model =
    DataStorage.saveLocal model.adventureIndex model.adventure model.globalSettings
        |> Task.attempt (\result -> LocalDataSaved result)



-- ol : List (Attribute msg) -> List ( String, Html msg ) -> Html msg
-- ol =
--   node "ol"
