module Main exposing (main)

import Adventure exposing (Adventure, AdventureId(..), AdventureIndex, Scene, createAdventureIndex)
import Browser exposing (Document)
import ChaosFactor exposing (ChaosFactor)
import Color
import DataStorage
import Dropbox
import Element exposing (..)
import Element.Background
import Element.Border
import Element.Font as Font
import Element.Input
import FateChart
import GlobalSettings exposing (GlobalSettings)
import Html.Attributes
import I18Next exposing (Translations)
import Json.Decode
import Material.Icons as MaterialIcons
import Maybe.Extra as MaybeX
import Random
import RollLog exposing (FateChartRoll, RollLogEntry(..))
import Styles
import Task
import TaskPort
import Time
import Url exposing (Url)
import Utils exposing (randomToTask, timestamp)
import Widget
import Widget.Material
import Widget.Material.Color as MaterialColor exposing (textAndBackground)
import Widget.Material.Typography exposing (body1, h5)



-- MAIN


main : Program () Model (Dropbox.Msg Msg)
main =
    Dropbox.application
        { init = \_ location -> ( init location, Cmd.none ) --( init location, loadGlobalData )
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
    , localSettings : LocalSettings
    , translations : List Translations
    , error : Maybe String
    , location : Url
    , selectedAdventureContentTab : Int
    }


type alias LocalSettings =
    { dropboxUserAuth : Maybe Dropbox.UserAuth }


asLocalSettingsIn : Model -> LocalSettings -> Model
asLocalSettingsIn model settings =
    { model | localSettings = settings }


asAdventureIn : Model -> Adventure -> Model
asAdventureIn model adventure =
    { model | adventure = Just adventure }


init : Url -> Model
init location =
    { adventure = Just testAdventure -- Nothing
    , adventureIndex = createAdventureIndex
    , globalSettings =
        { fateChartType = FateChart.Standard
        , latestAdventureId = Nothing
        , favoriteElementTables = []
        , saveTimestamp = 0
        }
    , localSettings =
        { dropboxUserAuth = Nothing }
    , translations = []
    , error = Nothing
    , location = location
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
    | RollFateChart FateChart.Probability
    | CreateRollLogEntry RollLogEntry
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

        RollFateChart probability ->
            case model.adventure of
                Just adventure ->
                    ( model
                    , RollLog.rollFateChart adventure.settings.fateChartType probability adventure.chaosFactor
                        |> Task.perform CreateRollLogEntry
                    )

                Nothing ->
                    ( model, Cmd.none )

        CreateRollLogEntry entry ->
            case model.adventure of
                Just adventure ->
                    ( { model | adventure = Just (Adventure.addRollLogEntry entry adventure) }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

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
            let
                localSettings : LocalSettings
                localSettings =
                    model.localSettings
            in
            ( { localSettings | dropboxUserAuth = Just auth.userAuth } |> asLocalSettingsIn model
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
        [ layout [ Element.Background.color (rgb255 225 225 240) ] <|
            column
                ([ width (fill |> maximum 1200)
                 , centerX
                 , height fill
                 , Font.family [ Font.typeface "Roboto", Font.typeface "Helvetica" ]
                 , Element.Background.color (rgb255 255 255 255)
                 ]
                    ++ body1
                )
                [ el [ width fill, centerX ] viewAppBar
                , el [ width fill, height fill, centerX ] mainView
                ]
        ]
    }


viewAppBar : Element Msg
viewAppBar =
    text "Mythic GME Adventures"


viewMain : Adventure -> Element Msg
viewMain adventure =
    row
        [ width fill
        , height fill
        , spacing 4
        ]
        [ el [ width (px 250), centerX, alignTop ] viewRollTables
        , el [ width (px 250), centerX, alignTop ] (viewRollLog adventure)
        , el [ width fill, centerX, alignTop ] (viewAdventure adventure)
        ]


viewRollTables : Element Msg
viewRollTables =
    column [ width fill ]
        [ viewContentWithHeader "Fate Chart" fill False viewFateChart
        , viewContentWithHeader "Meaning tables" fill True (text "Meaning tables content")
        ]


viewFateChart : Element Msg
viewFateChart =
    column [ width fill, Font.size 11 ]
        [ row [ width fill ]
            [ fateChartButton FateChart.Impossible
            , fateChartButton FateChart.NearlyImpossible
            ]
        , row [ width fill ]
            [ fateChartButton FateChart.VeryUnlikely
            , fateChartButton FateChart.Unlikely
            ]
        , fateChartButton FateChart.FiftyFifty
        , row [ width fill ]
            [ fateChartButton FateChart.Likely
            , fateChartButton FateChart.VeryLikely
            ]
        , row [ width fill ]
            [ fateChartButton FateChart.NearlyCertain
            , fateChartButton FateChart.Certain
            ]
        ]


fateChartButton : FateChart.Probability -> Element Msg
fateChartButton probability =
    Element.Input.button
        [ width fill
        , paddingXY 4 8
        , contentWithHeaderBorderColor
        , Element.Border.width 1
        , Font.center
        , Element.focused []
        ]
        { label = text (String.toUpper (FateChart.probabilityToString probability))
        , onPress = Just (RollFateChart probability)
        }


viewRollLog : Adventure -> Element Msg
viewRollLog adventure =
    column [ height fill ]
        (List.map viewRollLogEntry adventure.rollLog)


viewRollLogEntry : RollLogEntry -> Element Msg
viewRollLogEntry entry =
    case entry of
        RollLog.FateChartRollEntry roll ->
            viewFateChartRoll roll


viewFateChartRoll : FateChartRoll -> Element Msg
viewFateChartRoll roll =
    el [] (text "FateChartRoll")


viewAdventure : Adventure -> Element Msg
viewAdventure adventure =
    column [ width fill ]
        [ viewAdventureHeader adventure
        , viewAdventureLists
        , viewAdventureContents adventure
        ]


viewAdventureHeader : Adventure -> Element Msg
viewAdventureHeader adventure =
    row [ width fill ]
        [ viewChaosFactor
        , el [ centerX, Font.size 24 ] (text adventure.name)
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
    viewContentWithHeader "Chaos Factor" shrink True <|
        row [ centerX, Font.size 32 ]
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
            viewContentWithHeader "Threads" fill True <|
                viewListThread
        , el [ width (px 250) ] <|
            viewContentWithHeader "Characters" fill True <|
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
    text ("Scene " ++ String.fromInt index)


viewContentWithHeader : String -> Length -> Bool -> Element Msg -> Element Msg
viewContentWithHeader headerText viewWidth withPadding content =
    let
        contentPadding =
            if withPadding then
                padding 4

            else
                padding 0
    in
    column [ width viewWidth, contentWithHeaderBorderColor, Element.Border.width 1 ]
        [ el ([ centerX, width fill ] ++ textAndBackground contentWithHeaderColor) <|
            el [ centerX, paddingXY 8 4 ] (text headerText)
        , el [ width fill, contentPadding ] content
        ]


contentWithHeaderBorderColor : Attr decorative Msg
contentWithHeaderBorderColor =
    Element.Border.color (MaterialColor.fromColor contentWithHeaderColor)


contentWithHeaderColor : Color.Color
contentWithHeaderColor =
    MaterialColor.dark



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


testAdventure : Adventure
testAdventure =
    { id = AdventureId 1
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
