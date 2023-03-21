module Main exposing (..)

import FateChart exposing (FateChart)
import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)



-- MAIN


main : Program () Model Msg
main =
  Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model = Int

type alias Model2 =
  { campain : Maybe Campaign
  , campaigns : List Campaign
  , globalSettings : GlobalSettings
  }

type alias Campaign =
  { name : String
  , chaosFactor : Int
  , scenes : List Scene
  , threads : List Thread
  , characters : List Character
  , playableCharacters : List PlayableCharacter
  , rollLog : List RollLogEntry
  , notes : List CampaignNote
  , settings : CampaignSettings
  }

type alias Scene =
  { summary : Maybe String
  }


type SceneType 
  = Expected
  | Altered
  | Interrupted


testExpectedScene : Int -> SceneType
testExpectedScene chaosFactor = Expected


rollSceneAdjustment : List String
rollSceneAdjustment = [ "Remove A Character" ]

type alias Character =
  { name : String 
  , summary : Maybe String
  , notes : Maybe String
  }

type alias NonPlayableCharacter =
  { name : String
  , notes : String
  , motivation : String
  }

type alias PlayableCharacter =
  { name : String
  }

type alias Thread =
  { name : String
  , notes : String
  }

type alias CampaignNote =
  { title : Maybe String
  , text : String
  }

type alias RollLogEntry =
  { table : Maybe String
  , values : List Int
  , result : String
  }

type alias CampaignSettings =
  { fateChart : FateChart
  }

type alias GlobalSettings =
  { fateChart: FateChart
  }

init : Model
init =
  0



-- UPDATE


type Msg
  = Increment
  | Decrement


update : Msg -> Model -> Model
update msg model =
  case msg of
    Increment ->
      model + 1

    Decrement ->
      model - 1



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (String.fromInt model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]
