module Pages.Statistics.ComplexFood.Select.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (ComplexFoodId, JWT, ReferenceMapId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
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
    , complexFood : ComplexFood
    , foodStats : TotalOnlyStats
    , statisticsEvaluation : StatisticsEvaluation
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , referenceTrees : Maybe (DictList ReferenceMapId ReferenceNutrientTree)
    , complexFood : Maybe ComplexFood
    , complexFoodStats : Maybe TotalOnlyStats
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceTrees = Nothing
    , complexFood = Nothing
    , complexFoodStats = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map3
        (\referenceTrees complexFood complexFoodStats ->
            { jwt = i.jwt
            , complexFood = complexFood
            , foodStats = complexFoodStats
            , statisticsEvaluation = StatisticsUtil.initialWith referenceTrees
            , variant = StatisticsVariant.ComplexFood
            }
        )
        i.referenceTrees
        i.complexFood
        i.complexFoodStats


lenses :
    { initial :
        { referenceTrees : Lens Initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
        , complexFood : Lens Initial (Maybe ComplexFood)
        , complexFoodStats : Lens Initial (Maybe TotalOnlyStats)
        }
    , main :
        { complexFood : Lens Main ComplexFood
        , foodStats : Lens Main TotalOnlyStats
        , statisticsEvaluation : Lens Main StatisticsEvaluation
        }
    }
lenses =
    { initial =
        { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
        , complexFood = Lens .complexFood (\b a -> { a | complexFood = b })
        , complexFoodStats = Lens .complexFoodStats (\b a -> { a | complexFoodStats = b })
        }
    , main =
        { complexFood = Lens .complexFood (\b a -> { a | complexFood = b })
        , foodStats = Lens .foodStats (\b a -> { a | foodStats = b })
        , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , complexFoodId : ComplexFoodId
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = GotFetchStatsResponse (Result Error TotalOnlyStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchComplexFoodResponse (Result Error ComplexFood)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
