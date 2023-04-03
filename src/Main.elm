module Main exposing (main)

import Adventure exposing (Adventure, AdventureId(..), AdventureIndex, IndexAdventure, Scene, createAdventureIndex)
import Browser exposing (Document)
import Browser.Navigation exposing (load)
import DataStorage
import Dropbox
import Element exposing (..)
import FateChart
import GlobalSettings exposing (GlobalSettings)
import I18Next exposing (Translations)
import Json.Decode
import Material.Icons as MaterialIcons exposing (one_two_three)
import Maybe.Extra as MaybeX
import Styles
import Task
import TaskPort
import Url exposing (Url)
import Widget
import Widget.Material
import Widget.Material.Color as MaterialColor exposing (textAndBackground)



-- MAIN


main : Program () Model (Dropbox.Msg Msg)
main =
    Dropbox.application
        { init = \_ location -> ( init location, loadGlobalData )
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
    , selectedAdventureContentTab : Int
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
        , favoriteElementTables = []
        , saveTimestamp = 0
        }
    , translations = []
    , error = Nothing
    , location = location
    , dropboxInfo = Nothing
    , selectedAdventureContentTab = 0
    }



-- UPDATE


type Msg
    = LoadGlobalData
    | GlobalDataLoaded (Result DataStorage.LoadError ( AdventureIndex, GlobalSettings ))
    | CreateAdventure
    | AdventureCreated Adventure
    | LoadAdventure AdventureId
    | AdventureLoaded (Result DataStorage.LoadError Adventure)
    | SaveData
    | LocalDataSaved (Result DataStorage.SaveError ())
    | AvdentureContentTabUpdated Int
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
        LoadGlobalData ->
            ( model, loadGlobalData )

        GlobalDataLoaded result ->
            case result of
                Ok ( adventureIndex, settings ) ->
                    let
                        command =
                            case adventureIndex.adventures of
                                adventure :: _ ->
                                    loadAdventure adventure.id

                                [] ->
                                    Cmd.none
                    in
                    ( { model | adventureIndex = adventureIndex, globalSettings = settings }, command )

                Err error ->
                    handleLoadError model error

        CreateAdventure ->
            ( model
            , Adventure.createAdventure |> Task.perform (\adventure -> AdventureCreated adventure)
            )

        AdventureCreated adventure ->
            let
                index : AdventureIndex
                index =
                    Adventure.addAdventure adventure model.adventureIndex

                updatedModel =
                    { model
                        | adventure = Just adventure
                        , adventureIndex = index
                    }
            in
            ( updatedModel
            , saveData updatedModel
            )

        LoadAdventure id ->
            ( model, loadAdventure id )

        AdventureLoaded result ->
            case result of
                Ok adventure ->
                    ( { model | adventure = Just adventure }, Cmd.none )

                Err error ->
                    handleLoadError model error

        SaveData ->
            ( model, saveData model )

        LocalDataSaved result ->
            case result of
                Err error ->
                    ( { model | error = Just "Error" }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AvdentureContentTabUpdated index ->
            ( { model | selectedAdventureContentTab = index }
            , Cmd.none
            )

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


handleLoadError : Model -> DataStorage.LoadError -> ( Model, Cmd Msg )
handleLoadError model error =
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



-- VIEW


view : Model -> Document Msg
view model =
    let
        mainView : Element Msg
        mainView =
            case model.adventure of
                Just adventure ->
                    viewMain adventure

                Nothing ->
                    viewHome model
    in
    { title = "Mythic GME Adventures"
    , body =
        [ layout [] <|
            column
                [ width (fill |> maximum 1200)
                , centerX
                , height fill
                , explain Debug.todo
                ]
                [ el [ width fill, centerX ] viewAppBar
                , el [ width fill, height fill, centerX ] mainView
                ]
        ]
    }


viewAppBar : Element Msg
viewAppBar =
    text "app bar"


viewMain : Adventure -> Element Msg
viewMain adventure =
    row
        [ width fill
        , height fill
        , spacing 10
        , explain Debug.todo
        ]
        [ el [ width (px 250), centerX, alignTop ] viewRollTables
        , el [ width (px 250), centerX, alignTop ] viewRollLog
        , el [ width fill, centerX, alignTop ] (viewAdventure adventure)
        ]


viewRollTables : Element Msg
viewRollTables =
    column [ width fill ]
        [ viewContentWithHeader "Fate Chart" fill (text "Fate Chart content")
        , viewContentWithHeader "Meaning tables" fill (text "Meaning tables content")
        ]


viewRollLog : Element Msg
viewRollLog =
    column [ height fill ]
        [ viewRollLogEntry
        , viewRollLogEntry
        , viewRollLogEntry
        ]


viewRollLogEntry : Element Msg
viewRollLogEntry =
    text "roll log entry"


viewAdventure : Adventure -> Element Msg
viewAdventure adventure =
    column [ width fill ]
        [ viewAdventureHeader
        , viewAdventureLists
        , viewAdventureContents adventure
        ]


viewAdventureHeader : Element Msg
viewAdventureHeader =
    row [ width fill ]
        [ viewChaosFactor
        , el [ centerX ] (text "Adventure name")
        , el [ alignRight ] <|
            Widget.iconButton Styles.iconButton
                { text = "Toggle edit"
                , icon = MaterialIcons.edit |> Styles.iconMapper
                , onPress = Nothing
                }
        , Widget.iconButton Styles.iconButton
            { text = "Delete"
            , icon = MaterialIcons.delete |> Styles.iconMapper
            , onPress = Nothing
            }
        ]


viewChaosFactor : Element Msg
viewChaosFactor =
    viewContentWithHeader "Chaos Factor" shrink <|
        row [ centerX ]
            [ Widget.iconButton Styles.iconButton
                { text = "Decrement Chaos Factor"
                , icon = MaterialIcons.chevron_left |> Styles.iconMapper
                , onPress = Nothing
                }
            , text "5"
            , Widget.iconButton Styles.iconButton
                { text = "Increment Chaos Factor"
                , icon = MaterialIcons.chevron_right |> Styles.iconMapper
                , onPress = Nothing
                }
            ]


viewAdventureLists : Element Msg
viewAdventureLists =
    row [ width fill, spacing 4 ]
        [ el [ width fill ] <|
            viewContentWithHeader "Threads" fill <|
                viewListThread
        , el [ width fill ] <|
            viewContentWithHeader "Characters" fill <|
                viewListCharacter
        ]


viewListThread : Element Msg
viewListThread =
    text "Thread"


viewListCharacter : Element Msg
viewListCharacter =
    text "Character"


viewAdventureContents : Adventure -> Element Msg
viewAdventureContents adventure =
    let
        tabOptions : List { text : String, icon : b -> Element msg }
        tabOptions =
            [ { text = "Scenes"
              , icon = always Element.none
              }
            , { text = "Threads"
              , icon = always Element.none
              }
            , { text = "Characters"
              , icon = always Element.none
              }
            , { text = "Players"
              , icon = always Element.none
              }
            , { text = "Notes"
              , icon = always Element.none
              }
            ]
    in
    Widget.tab Styles.tab
        { tabs =
            { selected = Just 0
            , options = tabOptions
            , onSelect =
                \index ->
                    if index >= 0 && index <= List.length tabOptions then
                        Just (AvdentureContentTabUpdated index)

                    else
                        Nothing
            }
        , content =
            \index ->
                case index of
                    Just 0 ->
                        viewScenes adventure.scenes

                    _ ->
                        viewScenes adventure.scenes
        }


viewScenes : List Scene -> Element Msg
viewScenes scenes =
    column [] (scenes |> List.indexedMap viewScene)


viewScene : Int -> Scene -> Element Msg
viewScene index scene =
    text ("Scene" ++ String.fromInt index)


viewContentWithHeader : String -> Length -> Element Msg -> Element Msg
viewContentWithHeader headerText widthLength content =
    column [ width widthLength ]
        [ el ([ centerX, width fill ] ++ textAndBackground MaterialColor.dark) <|
            el [ centerX, paddingXY 8 4 ] (text headerText)
        , content
        ]



-- Widget.textButton Styles.containedButton
--                     { text = "Save"
--                     , onPress = Just SaveData
--                     }
-- view model =
--     { title = "Mythic GME Adventures"
--     , body =
--         [ div []
--             [ button [ onClick SaveData ] [ text "Save" ]
--             , button [ onClick LoadData ] [ text "Load" ]
--             , button [ onClick CreateAdventure ] [ text "Create adventure" ]
--             , div []
--                 [ ul [] (List.map viewIndexAdventure model.adventureIndex.adventures)
--                 ]
--             , button [ onClick LoginToDropbox ] [ text "Login" ]
--             , div [] [ HtmlX.viewMaybe viewAdventure model.adventure ]
--             , div [] [ text (Url.toString model.location) ]
--             , div []
--                 [ model.dropboxInfo
--                     |> Maybe.map (\_ -> "Login OK")
--                     |> HtmlX.viewMaybe (\res -> text res)
--                 ]
--             ]
--         ]
--     }
-- viewAdventure : Adventure -> Element Msg
-- viewAdventure adventure =
--     text adventure.name


viewHome : Model -> Element Msg
viewHome model =
    row [ centerX, centerY ]
        [ model.adventureIndex.adventures
            |> List.map
                (\adventure ->
                    Widget.fullBleedItem (Widget.Material.fullBleedItem Styles.appPalette)
                        { onPress = Just (LoadAdventure adventure.id)
                        , icon = always Element.none
                        , text = adventure.name
                        }
                )
            |> Widget.itemList (Widget.Material.cardColumn Styles.appPalette)
        , column [ alignTop ]
            [ Widget.iconButton Styles.containedButton <|
                { text = "New adventure"
                , icon = MaterialIcons.add |> Styles.iconMapper
                , onPress = Just CreateAdventure
                }
            ]
        ]


dropboxAppKey : String
dropboxAppKey =
    "9bebip9kkxmuo6g"


{-| Saves the adventures index, the current adventure and the global settings.
-}
saveData : Model -> Cmd Msg
saveData model =
    DataStorage.saveLocal model.adventureIndex model.adventure model.globalSettings
        |> Task.attempt (\result -> LocalDataSaved result)


loadGlobalData : Cmd Msg
loadGlobalData =
    DataStorage.loadLocal
        |> Task.attempt (\result -> GlobalDataLoaded result)


loadAdventure : AdventureId -> Cmd Msg
loadAdventure id =
    DataStorage.loadAdventure id
        |> Task.attempt (\result -> AdventureLoaded result)



-- ol : List (Attribute msg) -> List ( String, Html msg ) -> Html msg
-- ol =
--   node "ol"
