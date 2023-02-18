module Pages.Statistics.Recipe.Select.Requests exposing (fetchRecipe, fetchReferenceTrees, fetchStats)

import Addresses.Backend
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


fetchRecipe : Page.Flags -> Cmd Page.LogicMsg
fetchRecipe =
    Pages.Util.Requests.fetchRecipeWith Page.GotFetchRecipeResponse


fetchStats : Page.Flags -> Cmd Page.LogicMsg
fetchStats flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.stats.recipe flags.recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderTotalOnlyStats
        }
