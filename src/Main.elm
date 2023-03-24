module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import FateChart
import List.Extra as ListX
import Json.Decode as Decode exposing (Decoder, int)
import I18Next exposing (Translations)



-- MAIN


main : Program () Model2 Msg
main =
    Browser.sandbox { init = init, update = update, view = view }

-- MODEL


type alias Model2 = Int

type alias Model =
    { adventure : Maybe Adventure
    , adventures : List Adventure
    , globalSettings : GlobalSettings
    , translations : List Translations
    }

type alias Adventure =
    { id : Int
    , name : String
    , chaosFactor : Int
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


type alias Scene =
    { summary : Maybe String
    , notes : Maybe String
    }


type SceneType 
    = Expected
    | Altered
    | Interrupted


testExpectedScene : Int -> SceneType
testExpectedScene chaosFactor = Expected


rollSceneAdjustment : List String
rollSceneAdjustment = [ "Remove A Character" ]

rollPlayerCharacter : Model -> Maybe PlayerCharacter
rollPlayerCharacter model =
    model.adventure
    |> Maybe.andThen (\x ->  List.head x.playerCharacters) -- TODO


type alias Character =
    { id : CharacterId
    , name : String 
    , summary : Maybe String
    , notes : Maybe String
    }

type CharacterId 
    = CharacterId Int

characterIdDecoder : Decoder CharacterId
characterIdDecoder =
    Decode.map CharacterId int


type alias PlayerCharacter =
    { name : String
    }

type alias Thread =
    { id : Int
    , name : String
    , notes : String
    }

type alias AdventureNote =
    { title : Maybe String
    , text : String
    }

type alias RollLogEntry =
    { table : Maybe String
    , values : List Int
    , result : String
    }

type alias AdventureSettings =
    { fateChartType : FateChart.Type
    }

type alias GlobalSettings =
    { fateChartType: FateChart.Type
    }


init : Model2
init =
    0



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Msg -> Model2 -> Model2
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1



-- VIEW


view : Model2 -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model) ]
        , button [ onClick Increment ] [ text "+" ]
        ]
