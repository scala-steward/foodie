module Pages.Statistics.RecipeOccurrences.Handler exposing (..)

import Api.Types.RecipeOccurrence exposing (RecipeOccurrence)
import Pages.Statistics.RecipeOccurrences.Page as Page
import Pages.Statistics.RecipeOccurrences.Pagination exposing (Pagination)
import Pages.Statistics.RecipeOccurrences.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)

init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> Cmd Page.LogicMsg
initialFetch =
    Requests.fetchRecipeOccurrences


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