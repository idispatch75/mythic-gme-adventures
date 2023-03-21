module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import FateChart
import List.Extra as ListX



-- MAIN


main : Program () Model2 Msg
main =
  Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model2 = Int

type alias Model =
  { campain : Maybe Campaign
  , campaigns : List Campaign
  , globalSettings : GlobalSettings
  }

type alias Campaign =
  { name : String
  , chaosFactor : Int
  , scenes : List Scene
  , threadList : List Int
  , characterList : List Int
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

rollPlayableCharacter : Model -> Maybe PlayableCharacter
rollPlayableCharacter model =
	model.campain
    |> Maybe.andThen (\x ->  List.head x.playableCharacters) -- TODO


type alias Character =
  { id : Int
  , name : String 
  , summary : Maybe String
  , notes : Maybe String
  }

type alias PlayableCharacter =
  { name : String
  }

type alias Thread =
  { id : Int
  , name : String
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
