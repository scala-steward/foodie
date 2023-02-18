module Pages.Statistics.Meal.Select.Requests exposing (fetchMeal, fetchReferenceTrees, fetchStats)

import Addresses.Backend
import Api.Types.TotalOnlyStats exposing (decoderTotalOnlyStats)
import Http
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchReferenceTrees : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceTrees =
    StatisticsRequests.fetchReferenceTreesWith Page.GotFetchReferenceTreesResponse


fetchMeal : Page.Flags -> Cmd Page.LogicMsg
fetchMeal =
    Pages.Util.Requests.fetchMealWith Page.GotFetchMealResponse


fetchStats : Page.Flags -> Cmd Page.LogicMsg
fetchStats flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.stats.meal flags.mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderTotalOnlyStats
        }
