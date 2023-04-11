module Main exposing (main)

import Adventure
    exposing
        ( Adventure
        , AdventureId(..)
        , AdventureIndex
        , FateChartRoll
        , MeaningTableRoll
        , RandomEventRoll
        , RollLogEntry(..)
        , Scene
        , Thread
        , createAdventureIndex
        )
import Browser exposing (Document)
import Browser.Dom
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
import Html
import Html.Attributes exposing (id)
import I18Next exposing (Translations, tf, translationsDecoder)
import Json.Decode
import Json.Encode
import List.Extra as ListX
import Material.Icons as MaterialIcons
import Maybe.Extra as MaybeX
import RandomEvent exposing (RandomEventFocus(..))
import RollLog
import Styles
import Task
import TaskPort
import UI.Badge
import UI.RenderConfig
import UI.TextField as TextField
import Url exposing (Url)
import Utils exposing (heightPercent, maxHeightVh)
import Widget
import Widget.Customize
import Widget.Material
import Widget.Material.Color as MaterialColor exposing (textAndBackground)
import Widget.Material.Typography exposing (body1)



-- MAIN


main : Program Json.Encode.Value Model (Dropbox.Msg Msg)
main =
    Dropbox.application
        { init = \flags location -> ( init flags location, Cmd.none ) --( init location, loadGlobalData )
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
    , adventureEditMode : Bool
    , renderConfig : UI.RenderConfig.RenderConfig
    }


type alias LocalSettings =
    { dropboxUserAuth : Maybe Dropbox.UserAuth }


asLocalSettingsIn : Model -> LocalSettings -> Model
asLocalSettingsIn model settings =
    { model | localSettings = settings }


asAdventureIn : Model -> Adventure -> Model
asAdventureIn model adventure =
    { model | adventure = Just adventure }


init : Json.Encode.Value -> Url -> Model
init flags location =
    let
        translations =
            case Json.Decode.decodeValue translationsDecoder flags of
                Ok trans ->
                    [ trans, I18Next.initialTranslations ]

                Err _ ->
                    []
    in
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
    , translations = translations
    , error = Nothing
    , location = location
    , selectedAdventureContentTab = 0
    , adventureEditMode = False
    , renderConfig =
        UI.RenderConfig.init
            { width = 1000
            , height = 1000
            }
            UI.RenderConfig.localeEnglish
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
    | RollMeaningTable String
    | RollRandomEvent
    | CreateRollLogEntry RollLogEntry
    | IncreaseChaosFactor
    | DecreaseChaosFactor
    | ToggleAdventureEditMode
    | OnAdventureNameChanged String
    | LoginToDropbox
    | DropboxAuthResponseReceived Dropbox.AuthorizeResult
    | NoOp


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
                        , adventureEditMode = True
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
                    ( { model | adventure = Just adventure }, jumpToBottom rollLogId )

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
            handleAdventureMsg
                (\adventure ->
                    ( model
                    , RollLog.rollFateChart adventure.settings.fateChartType probability adventure.chaosFactor
                        |> Task.perform CreateRollLogEntry
                    )
                )
                model

        RollMeaningTable table ->
            ( model
            , RollLog.rollMeaningTable table
                |> Task.perform CreateRollLogEntry
            )

        RollRandomEvent ->
            handleAdventureMsg
                (\adventure ->
                    ( model
                    , RollLog.rollRandomEvent adventure.characters adventure.threads adventure.playerCharacters
                        |> Task.perform CreateRollLogEntry
                    )
                )
                model

        CreateRollLogEntry entry ->
            handleAdventureUpdateMsg
                (\adventure ->
                    ( Adventure.addRollLogEntry entry adventure
                    , jumpToBottom rollLogId
                    )
                )
                model

        IncreaseChaosFactor ->
            handleAdventureUpdateMsg
                (\adventure ->
                    ( { adventure | chaosFactor = ChaosFactor.offset 1 adventure.chaosFactor }
                    , Cmd.none
                    )
                )
                model

        DecreaseChaosFactor ->
            handleAdventureUpdateMsg
                (\adventure ->
                    ( { adventure | chaosFactor = ChaosFactor.offset -1 adventure.chaosFactor }
                    , Cmd.none
                    )
                )
                model

        ToggleAdventureEditMode ->
            ( { model | adventureEditMode = not model.adventureEditMode }
            , Cmd.none
            )

        OnAdventureNameChanged name ->
            handleAdventureUpdateMsg
                (\adventure ->
                    ( { adventure | name = name }
                    , Cmd.none
                    )
                )
                model

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

        NoOp ->
            ( model, Cmd.none )


handleAdventureUpdateMsg : (Adventure -> ( Adventure, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
handleAdventureUpdateMsg handler model =
    case model.adventure of
        Just adventure ->
            handler adventure |> Tuple.mapFirst (asAdventureIn model)

        Nothing ->
            ( model, Cmd.none )


handleAdventureMsg : (Adventure -> ( Model, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
handleAdventureMsg handler model =
    case model.adventure of
        Just adventure ->
            handler adventure

        Nothing ->
            ( model, Cmd.none )


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
                    viewMain model adventure

                Nothing ->
                    viewHome model
    in
    { title =
        case model.adventure of
            Just adventure ->
                adventure.name ++ " - Mythic GME Adventures"

            Nothing ->
                "Mythic GME Adventures"
    , body =
        [ layout [ Element.Background.color (rgb255 225 225 240), heightPercent 100, Element.htmlAttribute (Html.Attributes.style "line-height" "1.25") ] <|
            column
                (body1
                    ++ [ width (fill |> maximum 1200)
                       , centerX
                       , Font.family [ Font.typeface "Roboto", Font.typeface "Helvetica" ]
                       , Element.Background.color (rgb255 255 255 255)
                       , height fill
                       ]
                )
                [ el [ width fill, centerX, height (px 32) ] viewAppBar
                , el [ width fill, centerX, height fill ] mainView
                ]
        ]
    }


viewAppBar : Element Msg
viewAppBar =
    text "Mythic GME Adventures"


viewMain : Model -> Adventure -> Element Msg
viewMain model adventure =
    row
        [ width fill
        , height fill
        , spacing 4
        ]
        [ el [ width (px 250), centerX, height fill ] (viewRollTables model.translations)
        , el
            [ width (px 250)
            , centerX
            , height fill
            ]
            (viewRollLog model.translations adventure)
        , el [ width fill, centerX, alignTop ] (viewAdventure model adventure)
        ]


viewRollTables : List Translations -> Element Msg
viewRollTables translations =
    column [ width fill ]
        [ viewContentWithHeader "Fate Chart" fill False viewFateChart
        , viewContentWithHeader "Meaning tables" fill False (viewMeaningTables translations meaningTables)
        ]


viewFateChart : Element Msg
viewFateChart =
    column [ width fill, Font.size 11, Styles.fateChartColors.background ]
        [ row [ width fill ]
            [ fateChartButton FateChart.Certain
            , fateChartButton FateChart.NearlyCertain
            ]
        , row [ width fill ]
            [ fateChartButton FateChart.VeryLikely
            , fateChartButton FateChart.Likely
            ]
        , fateChartButton FateChart.FiftyFifty
        , row [ width fill ]
            [ fateChartButton FateChart.Unlikely
            , fateChartButton FateChart.VeryUnlikely
            ]
        , row [ width fill ]
            [ fateChartButton FateChart.NearlyImpossible
            , fateChartButton FateChart.Impossible
            ]
        ]


fateChartButton : FateChart.Probability -> Element Msg
fateChartButton probability =
    simpleButton (FateChart.probabilityToString probability) (Just (RollFateChart probability))


simpleButton : String -> Maybe Msg -> Element Msg
simpleButton label onPress =
    Element.Input.button
        [ width fill
        , paddingXY 4 8
        , contentWithHeaderBorderColor
        , Element.Border.width 1
        , Font.center
        , Element.focused []
        ]
        { label = text (String.toUpper label)
        , onPress = onPress
        }


meaningTables : List String
meaningTables =
    [ "actions"
    , "descriptions"
    , "character_actions_combat"
    , "character_actions_general"
    , "character_appearance"
    , "character_background"
    , "character_descriptors"
    , "character_identity"
    , "character_motivations"
    , "character_personality"
    , "character_skills"
    , "character_traits_flaws"
    , "city_descriptors"
    ]


viewMeaningTables : List Translations -> List String -> Element Msg
viewMeaningTables translations tables =
    column
        [ width fill
        , height fill
        , Font.size 14
        , Styles.meaningTableColors.background
        ]
        (tables |> List.map (\x -> viewMeaningTable translations x))


viewMeaningTable : List Translations -> String -> Element Msg
viewMeaningTable translations table =
    simpleButton (tf translations ("meaning_tables." ++ table ++ ".name")) (Just (RollMeaningTable table))


{-| The ID of the roll log column, used to scroll to the bottom of the column when a entry is added.
-}
rollLogId : String
rollLogId =
    "rollLog"


viewRollLog : List Translations -> Adventure -> Element Msg
viewRollLog translations adventure =
    column
        [ Element.htmlAttribute (id rollLogId)
        , width fill
        , height fill
        , scrollbarY
        , maxHeightVh 95
        , Element.Border.width 1
        ]
        (adventure.rollLog |> List.map (\entry -> viewRollLogEntry translations entry))


viewRollLogEntry : List Translations -> RollLogEntry -> Element Msg
viewRollLogEntry translations entry =
    case entry of
        FateChartRollEntry roll ->
            viewFateChartRoll roll

        MeaningTableRollEntry roll ->
            viewMeaningTableRoll translations roll

        RandomEventRollEntry roll ->
            viewRandomEventRoll roll


viewRollHeader : String -> Styles.RollColors decorative Msg -> Element Msg
viewRollHeader header colors =
    el ([ width fill, padding 4, Font.variant Font.smallCaps ] ++ colors.header) (text header)


viewFateChartRoll : FateChartRoll -> Element Msg
viewFateChartRoll roll =
    let
        digits : List Int
        digits =
            if roll.value > 10 then
                [ roll.value // 10, modBy 10 roll.value ]

            else
                [ roll.value ]

        hasEvent : Bool
        hasEvent =
            case digits of
                digit1 :: digit2 :: _ ->
                    digit1 == digit2 && digit1 <= ChaosFactor.toInt roll.chaosFactor

                _ ->
                    False
    in
    column [ width fill, Styles.fateChartColors.background ]
        [ viewRollHeader (FateChart.probabilityToString roll.probability) Styles.fateChartColors
        , viewRollResult roll.value (FateChart.outcomeToString roll.outcome)
        , if hasEvent then
            Widget.textButton (Styles.textButton |> Widget.Customize.elementButton [ Font.center ])
                { text = "Roll random event"
                , onPress = Just RollRandomEvent
                }
                |> el [ centerX ]

          else
            Element.none
        ]


viewMeaningTableRoll : List Translations -> MeaningTableRoll -> Element Msg
viewMeaningTableRoll translations roll =
    let
        header : Element Msg
        header =
            viewRollHeader (tf translations ("meaning_tables." ++ roll.table ++ ".name")) Styles.meaningTableColors

        results : List (Element Msg)
        results =
            roll.results
                |> List.map
                    (\result ->
                        let
                            translationKey =
                                "meaning_tables." ++ result.table ++ "." ++ String.fromInt result.value
                        in
                        viewRollResult result.value (tf translations translationKey)
                    )
    in
    column [ width fill, Styles.meaningTableColors.background ]
        (header :: results)


viewRandomEventRoll : RandomEventRoll -> Element Msg
viewRandomEventRoll roll =
    let
        focusTarget : Maybe String
        focusTarget =
            case roll.focus of
                RandomEvent.NpcEvent _ target ->
                    Just target

                RandomEvent.ThreadEvent _ target ->
                    Just target

                RandomEvent.PcEvent _ (Just target) ->
                    Just target

                _ ->
                    Nothing
    in
    column [ width fill, Styles.randomEventColors.background ]
        [ viewRollHeader "Random Event" Styles.randomEventColors
        , viewRollResult roll.value (RandomEvent.focusToString roll.focus)
        , case focusTarget of
            Just target ->
                el [ width fill, padding 4, Font.italic ] (textWithEllipse target)

            --Html.Attributes.style "padding" "4px"
            Nothing ->
                Element.none
        ]


viewRollResult : Int -> String -> Element Msg
viewRollResult value result =
    row [ width fill, padding 4 ]
        [ el [ width fill ] (text result)
        , el [ alignRight, Font.size 12, centerY ] (text (String.fromInt value))
        ]


viewAdventure : Model -> Adventure -> Element Msg
viewAdventure model adventure =
    column [ width fill, spacing 4, height fill ]
        [ viewAdventureHeader model adventure
        , viewAdventureLists adventure
        , viewAdventureContents model adventure
        ]


viewAdventureHeader : Model -> Adventure -> Element Msg
viewAdventureHeader model adventure =
    let
        adventureNameElement =
            if model.adventureEditMode then
                let
                    input =
                        TextField.singlelineText OnAdventureNameChanged "Adventure name" adventure.name
                            |> TextField.withPlaceholder "Adventure name"
                            |> TextField.withWidth TextField.widthFull
                            |> TextField.withOnEnterPressed ToggleAdventureEditMode
                            |> (if String.length adventure.name == 0 then
                                    TextField.withError "This field is required"

                                else
                                    identity
                               )
                            |> TextField.renderElement model.renderConfig
                in
                el [ centerX, padding 4, width fill ] input

            else
                paragraph [ centerX, Font.size 24, width fill, Font.center, padding 4 ] [ text adventure.name ]
    in
    row [ width fill ]
        [ viewChaosFactor adventure.chaosFactor
        , adventureNameElement
        , el [ alignRight ] <|
            Widget.iconButton Styles.smallIconButton
                { text = "Toggle edit"
                , icon =
                    (if model.adventureEditMode then
                        MaterialIcons.lock_open

                     else
                        MaterialIcons.lock
                    )
                        |> Styles.iconMapper
                , onPress = Just ToggleAdventureEditMode
                }
        , Widget.iconButton Styles.smallIconButton
            { text = "Delete"
            , icon = MaterialIcons.delete |> Styles.iconMapper
            , onPress = Nothing
            }
        ]


viewChaosFactor : ChaosFactor -> Element Msg
viewChaosFactor chaosFactor =
    viewContentWithHeader "Chaos Factor" shrink True <|
        row [ centerX, Font.size 32 ]
            [ Widget.iconButton Styles.iconButton
                { text = "Decrease Chaos Factor"
                , icon = MaterialIcons.chevron_left |> Styles.iconMapper
                , onPress = Just DecreaseChaosFactor
                }
            , text (ChaosFactor.toString chaosFactor)
            , Widget.iconButton Styles.iconButton
                { text = "Increase Chaos Factor"
                , icon = MaterialIcons.chevron_right |> Styles.iconMapper
                , onPress = Just IncreaseChaosFactor
                }
            ]


viewAdventureLists : Adventure -> Element Msg
viewAdventureLists adventure =
    row [ width fill, height fill, spacing 4 ]
        [ el [ width fill, alignTop, height fill ] <|
            viewContentWithHeader "Threads" fill True <|
                viewListThreads adventure
        , el [ width (px 250), alignTop, height fill ] <|
            viewContentWithHeader "Characters" fill True <|
                viewListCharacter
        ]


viewListThreads : Adventure -> Element Msg
viewListThreads adventure =
    column [ width (px 429), height (px 250), scrollbarY ] <|
        (ListX.joinOn
            (\_ thread -> thread)
            identity
            .id
            adventure.threadList
            adventure.threads
            |> List.map viewListThread
        )


viewListThread : Thread -> Element Msg
viewListThread thread =
    row [ width fill ]
        [ textWithEllipse thread.name
        , Widget.iconButton Styles.smallIconButton
            { text = "Duplicate"
            , icon = MaterialIcons.content_copy |> Styles.iconMapper
            , onPress = Nothing
            }
        , Widget.iconButton Styles.smallIconButton
            { text = "Delete"
            , icon = MaterialIcons.delete |> Styles.iconMapper
            , onPress = Nothing
            }
        ]


viewListCharacter : Element Msg
viewListCharacter =
    text "Character"


viewAdventureContents : Model -> Adventure -> Element Msg
viewAdventureContents model adventure =
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
                        viewScenes model adventure.scenes

                    _ ->
                        viewScenes model adventure.scenes
        }



-- el [ width fill, height fill ] <|
--     (UI.Tabs.tabList (\_ -> NoOp)
--         identity
--         [ "Scenes", "Threads" ]
--         "Scenes"
--         |> UI.Tabs.renderElement renderConfig
--     )


viewScenes : Model -> List Scene -> Element Msg
viewScenes model scenes =
    column [] (scenes |> List.indexedMap (\x -> viewScene model x))


viewScene : Model -> Int -> Scene -> Element Msg
viewScene model index scene =
    row [ width fill, spacing 4 ]
        [ UI.Badge.grayLight (String.fromInt (index + 1))
            |> UI.Badge.renderElement model.renderConfig
            |> el []
        , text (MaybeX.unwrap "" identity scene.summary)
        ]


viewContentWithHeader : String -> Length -> Bool -> Element Msg -> Element Msg
viewContentWithHeader headerText viewWidth withPadding content =
    let
        contentPadding =
            if withPadding then
                padding 4

            else
                padding 0
    in
    column [ width viewWidth, height fill, contentWithHeaderBorderColor, Element.Border.width 1 ]
        [ el ([ centerX, width fill ] ++ textAndBackground contentWithHeaderColor) <|
            el [ centerX, paddingXY 8 4, Font.variant Font.smallCaps, Font.size 18 ] (text headerText)
        , el [ width fill, height fill, contentPadding ] content
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


jumpToBottom : String -> Cmd Msg
jumpToBottom id =
    Browser.Dom.getViewportOf id
        |> Task.andThen (\info -> Browser.Dom.setViewportOf id 0 info.scene.height)
        |> Task.attempt (always NoOp)


textWithEllipse : String -> Element msg
textWithEllipse text =
    Html.div
        [ Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "line-height" "1.1"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "flex-basis" "auto"
        , Html.Attributes.style "flex-basis" "auto"
        ]
        [ Html.text text ]
        |> Element.html



-- ol : List (Attribute msg) -> List ( String, Html msg ) -> Html msg
-- ol =
--   node "ol"


testAdventure : Adventure
testAdventure =
    { id = AdventureId 1
    , name = "New adventure with a very long name that is very long"
    , chaosFactor = ChaosFactor.fromInt 9
    , scenes = [ { summary = Just "The hero meets the bad guy", notes = Nothing } ]
    , threadList = [ 1, 2, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1 ]
    , characterList = [ 1, 2 ]
    , threads = [ { id = 1, name = "Thread with a very long name bigger than the menght of the most lentghy whatever", notes = Nothing }, { id = 2, name = "Thread 2", notes = Nothing } ]
    , characters = [ { id = 1, name = "Char 1", summary = Nothing, notes = Nothing }, { id = 2, name = "Char 2", summary = Nothing, notes = Nothing } ]
    , playerCharacters = []
    , rollLog = [ RandomEventRollEntry { focus = ThreadEvent "positive" "Thread with a very long name that deos not fit", value = 1, timestamp = 1 } ]
    , notes = []
    , settings =
        { fateChartType = FateChart.Standard
        }
    , saveTimestamp = 0
    }
