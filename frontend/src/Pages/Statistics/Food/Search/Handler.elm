module Pages.Statistics.Food.Search.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Json.Decode as Decode
import Json.Encode as Encode
import Pages.Statistics.Food.Search.Page as Page
import Pages.Statistics.Food.Search.Pagination as Pagination exposing (Pagination)
import Pages.Statistics.Food.Search.Requests as Requests
import Pages.Statistics.Food.Search.Status as Status
import Ports
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , foods = []
      , foodsSearchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      , variant = StatisticsVariant.Food Nothing
      }
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
    ( model |> Page.lenses.foodsSearchString.set string
    , Cmd.none
    )


setFoodsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setFoodsPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


gotFetchFoodsResponse : Page.Model -> Result Error (List Food) -> ( Page.Model, Cmd Page.Msg )
gotFetchFoodsResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( setError error model, Cmd.none ))
            (\foods ->
                ( model |> Page.lenses.foods.set foods
                , foods
                    |> Encode.list encoderFood
                    |> Encode.encode 0
                    |> Ports.storeFoods
                )
            )


updateFoods : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateFoods model =
    Decode.decodeString (Decode.list decoderFood)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\foods ->
                ( model
                    |> Page.lenses.foods.set foods
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.foods).set
                        (foods
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty foods then
                    Requests.fetchFoods model.authorizedAccess

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
