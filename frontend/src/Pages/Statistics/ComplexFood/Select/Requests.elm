module Pages.Statistics.ComplexFood.Select.Requests exposing (fetchComplexFood, fetchReferenceTrees, fetchStats)

import Addresses.Backend
import Api.Types.ComplexFood exposing (decoderComplexFood)
import Api.Types.TotalOnlyStats exposing (decoderTotalOnlyStats)
import Http
import Pages.Statistics.ComplexFood.Select.Page as Page
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchReferenceTrees : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceTrees =
    StatisticsRequests.fetchReferenceTreesWith Page.GotFetchReferenceTreesResponse


fetchComplexFood : Page.Flags -> Cmd Page.LogicMsg
fetchComplexFood flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.complexFoods.single flags.complexFoodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchComplexFoodResponse decoderComplexFood
        }


fetchStats : Page.Flags -> Cmd Page.LogicMsg
fetchStats flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.stats.complexFood flags.complexFoodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderTotalOnlyStats
        }
