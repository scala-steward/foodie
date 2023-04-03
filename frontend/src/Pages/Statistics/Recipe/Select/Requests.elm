module Pages.Statistics.Recipe.Select.Requests exposing (fetchRecipe, fetchReferenceTrees, fetchStats)

import Addresses.Backend
import Api.Auxiliary exposing (RecipeId)
import Api.Types.TotalOnlyStats exposing (decoderTotalOnlyStats)
import Http
import Pages.Statistics.Recipe.Select.Page as Page
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchReferenceTrees : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceTrees =
    StatisticsRequests.fetchReferenceTreesWith Page.GotFetchReferenceTreesResponse


fetchRecipe : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
fetchRecipe =
    Pages.Util.Requests.fetchRecipeWith Page.GotFetchRecipeResponse


fetchStats : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
fetchStats authorizedAccess recipeId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.stats.recipe recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderTotalOnlyStats
        }
