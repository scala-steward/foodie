module Pages.Statistics.Recipe.Search.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Basics.Extra exposing (flip)
import Json.Decode as Decode
import Pages.Statistics.Recipe.Search.Page as Page
import Pages.Statistics.Recipe.Search.Pagination as Pagination exposing (Pagination)
import Pages.Statistics.Recipe.Search.Requests as Requests
import Pages.Statistics.Recipe.Search.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , recipes = []
      , recipesSearchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      , variant = StatisticsVariant.Recipe StatisticsVariant.None
      }
    , initialFetch flags.authorizedAccess
    )


initialFetch : AuthorizedAccess -> Cmd Page.Msg
initialFetch =
    Requests.fetchRecipes


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetSearchString string ->
            setSearchString model string

        Page.SetRecipesPagination pagination ->
            setRecipesPagination model pagination

        Page.GotFetchRecipesResponse result ->
            gotFetchRecipesResponse model result

        Page.UpdateRecipes string ->
            updateRecipes model string


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model |> Page.lenses.recipesSearchString.set string
    , Cmd.none
    )


setRecipesPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setRecipesPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\recipes ->
                model
                    |> Page.lenses.recipes.set recipes
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipes).set True
            )
    , Cmd.none
    )


updateRecipes : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateRecipes model =
    Decode.decodeString (Decode.list decoderRecipe)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\recipes ->
                ( model
                    |> Page.lenses.recipes.set recipes
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipes).set
                        (recipes
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty recipes then
                    Requests.fetchRecipes model.authorizedAccess

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
