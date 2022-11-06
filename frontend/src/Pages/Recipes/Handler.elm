module Pages.Recipes.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.Recipes.Page as Page exposing (RecipeState)
import Pages.Recipes.Pagination as Pagination exposing (Pagination)
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Requests as Requests
import Pages.Recipes.Status as Status
import Pages.Util.PaginationSettings as PaginationSettings
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , recipes = Dict.empty
      , recipeToAdd = Nothing
      , searchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , Requests.fetchRecipes flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateRecipeCreation recipeCreationClientInput ->
            updateRecipeCreation model recipeCreationClientInput

        Page.CreateRecipe ->
            createRecipe model

        Page.GotCreateRecipeResponse dataOrError ->
            gotCreateRecipeResponse model dataOrError

        Page.UpdateRecipe recipeUpdate ->
            updateRecipe model recipeUpdate

        Page.SaveRecipeEdit recipeId ->
            saveRecipeEdit model recipeId

        Page.GotSaveRecipeResponse dataOrError ->
            gotSaveRecipeResponse model dataOrError

        Page.EnterEditRecipe recipeId ->
            enterEditRecipe model recipeId

        Page.ExitEditRecipeAt recipeId ->
            exitEditRecipeAt model recipeId

        Page.RequestDeleteRecipe recipeId ->
            requestDeleteRecipe model recipeId

        Page.ConfirmDeleteRecipe recipeId ->
            confirmDeleteRecipe model recipeId

        Page.CancelDeleteRecipe recipeId ->
            cancelDeleteRecipe model recipeId

        Page.GotDeleteRecipeResponse deletedId dataOrError ->
            gotDeleteRecipeResponse model deletedId dataOrError

        Page.GotFetchRecipesResponse dataOrError ->
            gotFetchRecipesResponse model dataOrError

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.SetSearchString string ->
            setSearchString model string


updateRecipeCreation : Page.Model -> Maybe RecipeCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipeCreation model recipeToAdd =
    ( model
        |> Page.lenses.recipeToAdd.set recipeToAdd
    , Cmd.none
    )


createRecipe : Page.Model -> ( Page.Model, Cmd Page.Msg )
createRecipe model =
    ( model
    , model.recipeToAdd
        |> Maybe.Extra.unwrap Cmd.none (RecipeCreationClientInput.toCreation >> Requests.createRecipe model.authorizedAccess)
    )


gotCreateRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotCreateRecipeResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\recipe ->
                model
                    |> Lens.modify Page.lenses.recipes
                        (Dict.insert recipe.id (Editing.asView recipe))
                    |> Page.lenses.recipeToAdd.set Nothing
            )
    , Cmd.none
    )


updateRecipe : Page.Model -> RecipeUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipe model recipeUpdate =
    ( model
        |> mapRecipeOrUpdateById recipeUpdate.id
            (Editing.lenses.update.set recipeUpdate)
    , Cmd.none
    )


saveRecipeEdit : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
saveRecipeEdit model recipeId =
    ( model
    , model
        |> Page.lenses.recipes.get
        |> Dict.get recipeId
        |> Maybe.andThen Editing.extractUpdate
        |> Maybe.Extra.unwrap
            Cmd.none
            (RecipeUpdateClientInput.to
                >> Requests.saveRecipe model.authorizedAccess
            )
    )


gotSaveRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotSaveRecipeResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\recipe ->
                model
                    |> mapRecipeOrUpdateById recipe.id
                        (always (Editing.asView recipe))
            )
    , Cmd.none
    )


enterEditRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
enterEditRecipe model recipeId =
    ( model
        |> mapRecipeOrUpdateById recipeId
            (Editing.viewToUpdate RecipeUpdateClientInput.from)
    , Cmd.none
    )


exitEditRecipeAt : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
exitEditRecipeAt model recipeId =
    ( model |> mapRecipeOrUpdateById recipeId Editing.anyToView
    , Cmd.none
    )


requestDeleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
requestDeleteRecipe model recipeId =
    ( model |> mapRecipeOrUpdateById recipeId Editing.viewToDelete
    , Cmd.none
    )


confirmDeleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteRecipe model recipeId =
    ( model
    , Requests.deleteRecipe model.authorizedAccess recipeId
    )


cancelDeleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteRecipe model recipeId =
    ( model |> mapRecipeOrUpdateById recipeId Editing.anyToView
    , Cmd.none
    )


gotDeleteRecipeResponse : Page.Model -> RecipeId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteRecipeResponse model deletedId dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (always
                (model
                    |> Lens.modify Page.lenses.recipes (Dict.remove deletedId)
                )
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\recipes ->
                model
                    |> Page.lenses.recipes.set
                        (recipes
                            |> List.map (\r -> ( r.id, r |> Editing.asView ))
                            |> Dict.fromList
                        )
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipes).set True
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.searchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.recipes
        }
        model
        string
    , Cmd.none
    )


mapRecipeOrUpdateById : RecipeId -> (Page.RecipeState -> Page.RecipeState) -> Page.Model -> Page.Model
mapRecipeOrUpdateById recipeId =
    Page.lenses.recipes
        |> LensUtil.updateById recipeId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
