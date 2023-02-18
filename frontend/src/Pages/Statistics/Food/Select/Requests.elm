module Pages.Statistics.Food.Select.Requests exposing (fetchFoodInfo, fetchReferenceTrees, fetchStats)

import Addresses.Backend
import Api.Types.FoodInfo exposing (decoderFoodInfo)
import Api.Types.FoodStats exposing (decoderFoodStats)
import Http
import Pages.Statistics.Food.Select.Page as Page
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchReferenceTrees : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceTrees =
    StatisticsRequests.fetchReferenceTreesWith Page.GotFetchReferenceTreesResponse


fetchFoodInfo : Page.Flags -> Cmd Page.LogicMsg
fetchFoodInfo flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.recipes.food flags.foodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchFoodInfoResponse decoderFoodInfo
        }


fetchStats : Page.Flags -> Cmd Page.LogicMsg
fetchStats flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.stats.food flags.foodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderFoodStats
        }
