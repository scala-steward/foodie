module Pages.Statistics.ComplexFood.Search.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.ComplexFood exposing (ComplexFood, decoderComplexFood)
import Basics.Extra exposing (flip)
import Json.Decode as Decode
import Pages.Statistics.ComplexFood.Search.Page as Page
import Pages.Statistics.ComplexFood.Search.Pagination as Pagination exposing (Pagination)
import Pages.Statistics.ComplexFood.Search.Requests as Requests
import Pages.Statistics.ComplexFood.Search.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , complexFoods = []
      , complexFoodsSearchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      , variant = StatisticsVariant.ComplexFood
      }
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

        Page.UpdateComplexFoods string ->
            updateComplexFoods model string


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model |> Page.lenses.complexFoodsSearchString.set string
    , Cmd.none
    )


setComplexFoodsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setComplexFoodsPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFoods ->
                model
                    |> Page.lenses.complexFoods.set complexFoods
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFoods).set True
            )
    , Cmd.none
    )


updateComplexFoods : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateComplexFoods model =
    Decode.decodeString (Decode.list decoderComplexFood)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\complexFoods ->
                ( model
                    |> Page.lenses.complexFoods.set complexFoods
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFoods).set
                        (complexFoods
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty complexFoods then
                    Requests.fetchComplexFoods model.authorizedAccess

                  else
                    Cmd.none
                )
            )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization


setJsonError : Decode.Error -> Page.Model -> Page.Model
setJsonError =
    HttpUtil.setJsonError Page.lenses.initialization
