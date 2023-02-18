module Pages.Statistics.Meal.Search.Handler exposing (init, update)

import Api.Types.Meal exposing (Meal)
import Pages.Statistics.Meal.Search.Page as Page
import Pages.Statistics.Meal.Search.Pagination exposing (Pagination)
import Pages.Statistics.Meal.Search.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess
    )


initialFetch : AuthorizedAccess -> Cmd Page.Msg
initialFetch =
    Requests.fetchMeals


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetSearchString string ->
            setSearchString model string

        Page.SetMealsPagination pagination ->
            setMealsPagination model pagination

        Page.GotFetchMealsResponse result ->
            gotFetchMealsResponse model result


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model |> Tristate.mapMain (Page.lenses.main.mealsSearchString.set string)
    , Cmd.none
    )


setMealsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setMealsPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


gotFetchMealsResponse : Page.Model -> Result Error (List Meal) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\meals ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.meals.set (meals |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )
