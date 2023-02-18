module Pages.Statistics.Food.Select.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (FoodId, JWT, ReferenceMapId)
import Api.Types.FoodInfo exposing (FoodInfo)
import Api.Types.FoodStats exposing (FoodStats)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil as StatisticsUtil exposing (ReferenceNutrientTree, StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , foodInfo : FoodInfo
    , foodStats : FoodStats
    , statisticsEvaluation : StatisticsEvaluation
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , referenceTrees : Maybe (DictList ReferenceMapId ReferenceNutrientTree)
    , foodInfo : Maybe FoodInfo
    , foodStats : Maybe FoodStats
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceTrees = Nothing
    , foodInfo = Nothing
    , foodStats = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map3
        (\referenceTrees foodInfo foodStats ->
            { jwt = i.jwt
            , foodInfo = foodInfo
            , foodStats = foodStats
            , statisticsEvaluation = StatisticsUtil.initialWith referenceTrees
            , variant = StatisticsVariant.Food
            }
        )
        i.referenceTrees
        i.foodInfo
        i.foodStats


lenses :
    { initial :
        { referenceTrees : Lens Initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
        , foodInfo : Lens Initial (Maybe FoodInfo)
        , foodStats : Lens Initial (Maybe FoodStats)
        }
    , main :
        { foodInfo : Lens Main FoodInfo
        , foodStats : Lens Main FoodStats
        , statisticsEvaluation : Lens Main StatisticsEvaluation
        }
    }
lenses =
    { initial =
        { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
        , foodInfo = Lens .foodInfo (\b a -> { a | foodInfo = b })
        , foodStats = Lens .foodStats (\b a -> { a | foodStats = b })
        }
    , main =
        { foodInfo = Lens .foodInfo (\b a -> { a | foodInfo = b })
        , foodStats = Lens .foodStats (\b a -> { a | foodStats = b })
        , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , foodId : FoodId
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = GotFetchStatsResponse (Result Error FoodStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchFoodInfoResponse (Result Error FoodInfo)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
