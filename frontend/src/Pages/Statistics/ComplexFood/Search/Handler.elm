module Pages.Statistics.ComplexFood.Search.Handler exposing (init, update)

import Api.Types.ComplexFood exposing (ComplexFood)
import Pages.Statistics.ComplexFood.Search.Page as Page
import Pages.Statistics.ComplexFood.Search.Pagination exposing (Pagination)
import Pages.Statistics.ComplexFood.Search.Requests as Requests
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
    Requests.fetchComplexFoods


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetSearchString string ->
            setSearchString model string

        Page.SetComplexFoodsPagination pagination ->
            setComplexFoodsPagination model pagination

        Page.GotFetchComplexFoodsResponse result ->
            gotFetchComplexFoodsResponse model result


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model |> Tristate.mapMain (Page.lenses.main.complexFoodsSearchString.set string)
    , Cmd.none
    )


setComplexFoodsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setComplexFoodsPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexFoods ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.complexFoods.set (complexFoods |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )
