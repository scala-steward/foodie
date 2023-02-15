module Pages.Statistics.Food.Search.Handler exposing (init, update)

import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Pages.Statistics.Food.Search.Page as Page
import Pages.Statistics.Food.Search.Pagination exposing (Pagination)
import Pages.Statistics.Food.Search.Requests as Requests
import Pages.View.Tristate as Tristate
import Ports
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch
    )


initialFetch : Cmd Page.Msg
initialFetch =
    Ports.doFetchFoods ()


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetSearchString string ->
            setSearchString model string

        Page.SetFoodsPagination pagination ->
            setFoodsPagination model pagination

        Page.GotFetchFoodsResponse result ->
            gotFetchFoodsResponse model result

        Page.UpdateFoods string ->
            updateFoods model string


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model |> Tristate.mapMain (Page.lenses.main.foodsSearchString.set string)
    , Cmd.none
    )


setFoodsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setFoodsPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


gotFetchFoodsResponse : Page.Model -> Result Error (List Food) -> ( Page.Model, Cmd Page.Msg )
gotFetchFoodsResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model.configuration error, Cmd.none ))
            (\foods ->
                ( model |> Tristate.mapInitial (Page.lenses.initial.foods.set (foods |> Just))
                , foods
                    |> Encode.list encoderFood
                    |> Encode.encode 0
                    |> Ports.storeFoods
                )
            )


updateFoods : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateFoods model =
    Decode.decodeString (Decode.list decoderFood)
        >> Result.Extra.unpack (\error -> ( error |> HttpUtil.jsonErrorToError |> Tristate.toError model.configuration, Cmd.none ))
            (\foods ->
                ( model
                    |> Tristate.mapInitial (Page.lenses.initial.foods.set (foods |> Just |> Maybe.Extra.filter (List.isEmpty >> not)))
                    |> Tristate.fromInitToMain Page.initialToMain
                , model
                    |> Tristate.lenses.initial.getOption
                    |> Maybe.Extra.filter (always (foods |> List.isEmpty))
                    |> Maybe.Extra.unwrap Cmd.none
                        (\initial ->
                            Requests.fetchFoods
                                { configuration = model.configuration
                                , jwt = initial.jwt
                                }
                        )
                )
            )
