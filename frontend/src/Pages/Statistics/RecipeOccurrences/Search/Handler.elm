module Pages.Statistics.RecipeOccurrences.Search.Handler exposing (init, update)

import Api.Auxiliary exposing (ProfileId)
import Api.Types.Profile exposing (Profile)
import Api.Types.RecipeOccurrence exposing (RecipeOccurrence)
import Pages.Statistics.RecipeOccurrences.Search.Page as Page
import Pages.Statistics.RecipeOccurrences.Search.Pagination exposing (Pagination)
import Pages.Statistics.RecipeOccurrences.Search.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess flags.profileId |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> ProfileId -> Cmd Page.LogicMsg
initialFetch authorizedAccess profileId =
    Cmd.batch
        [ Requests.fetchRecipeOccurrences authorizedAccess profileId
        , Pages.Util.Requests.fetchProfileWith Page.GotFetchProfileResponse authorizedAccess profileId
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.SetSearchString string ->
            setSearchString model string

        Page.SetRecipeOccurrencesPagination pagination ->
            setRecipesPagination model pagination

        Page.GotFetchRecipeOccurrencesResponse result ->
            gotFetchRecipeOccurrencesResponse model result

        Page.GotFetchProfileResponse result ->
            gotFetchProfileResponse model result

        Page.SortBy sortType ->
            sortBy model sortType


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setSearchString model string =
    ( model |> Tristate.mapMain (Page.lenses.main.recipesSearchString.set string)
    , Cmd.none
    )


setRecipesPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setRecipesPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


gotFetchRecipeOccurrencesResponse : Page.Model -> Result Error (List RecipeOccurrence) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchRecipeOccurrencesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipes ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.recipeOccurrences.set (recipes |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchProfileResponse : Page.Model -> Result Error Profile -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchProfileResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\profile ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.profile.set (profile |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


sortBy : Page.Model -> Page.SortType -> ( Page.Model, Cmd Page.LogicMsg )
sortBy model sortType =
    ( model |> Tristate.mapMain (Page.lenses.main.sortType.set sortType)
    , Cmd.none
    )
