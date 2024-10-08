module Pages.Statistics.Time.Handler exposing (init, update)

import Api.Auxiliary exposing (ProfileId, ReferenceMapId)
import Api.Lenses.StatsLens as StatsLens
import Api.Types.Date exposing (Date)
import Api.Types.Profile exposing (Profile)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.Stats exposing (Stats)
import Basics.Extra exposing (flip)
import Maybe.Extra
import Monocle.Lens as Lens
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Statistics.Time.Page as Page
import Pages.Statistics.Time.Pagination exposing (Pagination)
import Pages.Statistics.Time.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> Cmd Page.LogicMsg
initialFetch authorizedAccess =
    Cmd.batch
        [ Requests.fetchReferenceTrees authorizedAccess
        , Requests.fetchProfiles authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.SetFromDate maybeDate ->
            setFromDate model maybeDate

        Page.SetToDate maybeDate ->
            setToDate model maybeDate

        Page.FetchStats ->
            fetchStats model

        Page.GotFetchStatsResponse result ->
            gotFetchStatsResponse model result

        Page.GotFetchReferenceTreesResponse result ->
            gotFetchReferenceTreesResponse model result

        Page.GotFetchProfilesResponse result ->
            gotFetchProfilesResponse model result

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.SelectReferenceMap referenceMapId ->
            selectReferenceMap model referenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string

        Page.SelectProfile maybeProfileId ->
            selectProfile model maybeProfileId


setFromDate : Page.Model -> Maybe Date -> ( Page.Model, Cmd Page.LogicMsg )
setFromDate model maybeDate =
    ( model
        |> Tristate.mapMain
            (Page.lenses.main.from.set maybeDate
                >> Page.lenses.main.status.set Page.Select
            )
    , Cmd.none
    )


setToDate : Page.Model -> Maybe Date -> ( Page.Model, Cmd Page.LogicMsg )
setToDate model maybeDate =
    ( model
        |> Tristate.mapMain
            (Page.lenses.main.to.set maybeDate
                >> Page.lenses.main.status.set Page.Select
            )
    , Cmd.none
    )


fetchStats : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
fetchStats model =
    ( model
        |> Tristate.mapMain (Page.lenses.main.status.set Page.Fetch)
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                main.selectedProfile
                    |> Maybe.Extra.unwrap Cmd.none
                        (\profile ->
                            Requests.fetchStats
                                { jwt = main.jwt
                                , configuration = model.configuration
                                }
                                profile.id
                                main.requestInterval
                        )
            )
    )


gotFetchStatsResponse : Page.Model -> Result Error Stats -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\stats ->
                model
                    |> Tristate.mapMain
                        (Page.lenses.main.stats.set
                            (stats |> Lens.modify StatsLens.nutrients (List.sortBy (.base >> .name)))
                            >> Page.lenses.main.status.set Page.Display
                        )
            )
    , Cmd.none
    )


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith
        { referenceTreesLens = Page.lenses.initial.referenceTrees
        , initialToMain = Page.initialToMain
        }


gotFetchProfilesResponse : Page.Model -> Result Error (List Profile) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchProfilesResponse =
    StatisticsRequests.gotFetchProfilesResponseWith
        { profilesLens = Page.lenses.initial.profiles
        , initialToMain = Page.initialToMain
        }


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


selectReferenceMap : Page.Model -> Maybe ReferenceMapId -> ( Page.Model, Cmd Page.LogicMsg )
selectReferenceMap =
    StatisticsRequests.selectReferenceMapWith
        { statisticsEvaluationLens = Page.lenses.main.statisticsEvaluation
        }


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setNutrientsSearchString =
    StatisticsRequests.setNutrientsSearchStringWith
        { statisticsEvaluationLens = Page.lenses.main.statisticsEvaluation
        }


selectProfile : Page.Model -> Maybe ProfileId -> ( Page.Model, Cmd Page.LogicMsg )
selectProfile model maybeProfileId =
    ( model
        |> Tristate.mapMain
            ((\main ->
                maybeProfileId
                    |> Maybe.andThen (flip DictList.get main.profiles)
                    |> flip Page.lenses.main.selectedProfile.set main
             )
                >> Page.lenses.main.status.set Page.Select
            )
    , Cmd.none
    )
