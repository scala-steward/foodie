module Pages.Statistics.Recipe.Select.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (JWT, RecipeId, ReferenceMapId)
import Api.Types.Recipe exposing (Recipe)
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
    , recipe : Recipe
    , recipeStats : TotalOnlyStats
    , statisticsEvaluation : StatisticsEvaluation
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , referenceTrees : Maybe (DictList ReferenceMapId ReferenceNutrientTree)
    , recipe : Maybe Recipe
    , recipeStats : Maybe TotalOnlyStats
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceTrees = Nothing
    , recipe = Nothing
    , recipeStats = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map3
        (\referenceTrees recipe recipeStats ->
            { jwt = i.jwt
            , recipe = recipe
            , recipeStats = recipeStats
            , statisticsEvaluation = StatisticsUtil.initialWith referenceTrees
            , variant = StatisticsVariant.Recipe
            }
        )
        i.referenceTrees
        i.recipe
        i.recipeStats


lenses :
    { initial :
        { referenceTrees : Lens Initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
        , recipe : Lens Initial (Maybe Recipe)
        , recipeStats : Lens Initial (Maybe TotalOnlyStats)
        }
    , main :
        { recipe : Lens Main Recipe
        , recipeStats : Lens Main TotalOnlyStats
        , statisticsEvaluation : Lens Main StatisticsEvaluation
        }
    }
lenses =
    { initial =
        { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
        , recipe = Lens .recipe (\b a -> { a | recipe = b })
        , recipeStats = Lens .recipeStats (\b a -> { a | recipeStats = b })
        }
    , main =
        { recipe = Lens .recipe (\b a -> { a | recipe = b })
        , recipeStats = Lens .recipeStats (\b a -> { a | recipeStats = b })
        , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = GotFetchStatsResponse (Result Error TotalOnlyStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchRecipeResponse (Result Error Recipe)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
