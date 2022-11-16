module Pages.Statistics.Meal.Search.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Meal exposing (Meal, decoderMeal)
import Basics.Extra exposing (flip)
import Json.Decode as Decode
import Pages.Statistics.Meal.Search.Page as Page
import Pages.Statistics.Meal.Search.Pagination as Pagination exposing (Pagination)
import Pages.Statistics.Meal.Search.Requests as Requests
import Pages.Statistics.Meal.Search.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , meals = []
      , mealsSearchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      , variant = StatisticsVariant.Meal
      }
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

        Page.UpdateMeals string ->
            updateMeals model string


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model |> Page.lenses.mealsSearchString.set string
    , Cmd.none
    )


setMealsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setMealsPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


gotFetchMealsResponse : Page.Model -> Result Error (List Meal) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\meals ->
                model
                    |> Page.lenses.meals.set meals
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meals).set True
            )
    , Cmd.none
    )


updateMeals : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateMeals model =
    Decode.decodeString (Decode.list decoderMeal)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\meals ->
                ( model
                    |> Page.lenses.meals.set meals
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meals).set
                        (meals
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty meals then
                    Requests.fetchMeals model.authorizedAccess

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
