module Pages.Statistics.Time.Requests exposing (fetchProfiles, fetchReferenceTrees, fetchStats)

import Addresses.Backend
import Api.Auxiliary exposing (ProfileId)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (decoderStats)
import Http
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Statistics.Time.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Requests
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchReferenceTrees : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceTrees =
    StatisticsRequests.fetchReferenceTreesWith Page.GotFetchReferenceTreesResponse


fetchProfiles : AuthorizedAccess -> Cmd Page.LogicMsg
fetchProfiles =
    Pages.Util.Requests.fetchProfilesWith Page.GotFetchProfilesResponse


fetchStats : AuthorizedAccess -> ProfileId -> RequestInterval -> Cmd Page.LogicMsg
fetchStats authorizedAccess profileId requestInterval =
    let
        toQuery name =
            Maybe.map (DateUtil.dateToString >> Url.Builder.string name)

        interval =
            { from = requestInterval.from |> toQuery "from"
            , to = requestInterval.to |> toQuery "to"
            }
    in
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.stats.all profileId interval)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderStats
        }
