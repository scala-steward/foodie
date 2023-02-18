module Pages.Recipes.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional
import Pages.Recipes.Page as Page exposing (RecipeState)
import Pages.Recipes.Pagination as Pagination exposing (Pagination)
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Requests as Requests
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , Requests.fetchRecipes flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.GotFetchRecipesResponse dataOrError ->
            gotFetchRecipesResponse model dataOrError

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

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.SetSearchString string ->
            setSearchString model string


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipes ->
                model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.recipes.set
                            (recipes
                                |> List.map Editing.asView
                                |> DictList.fromListWithKey (.original >> .id)
                                |> Just
                            )
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


updateRecipeCreation : Page.Model -> Maybe RecipeCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipeCreation model recipeToAdd =
    ( model
        |> Tristate.mapMain (Page.lenses.main.recipeToAdd.set recipeToAdd)
    , Cmd.none
    )


createRecipe : Page.Model -> ( Page.Model, Cmd Page.Msg )
createRecipe model =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main.recipeToAdd
                    |> Maybe.map
                        (RecipeCreationClientInput.toCreation
                            >> Requests.createRecipe
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotCreateRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotCreateRecipeResponse model dataOrError =
    dataOrError
        |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
            (\recipe ->
                ( model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId recipe.id
                            Page.lenses.main.recipes
                            (recipe |> Editing.asView)
                            >> Page.lenses.main.recipeToAdd.set Nothing
                        )
                , recipe.id
                    |> Addresses.Frontend.ingredientEditor.address
                    |> Links.loadFrontendPage model.configuration
                )
            )


updateRecipe : Page.Model -> RecipeUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipe model recipeUpdate =
    ( model
        |> mapRecipeStateById recipeUpdate.id
            (Editing.lenses.update.set recipeUpdate)
    , Cmd.none
    )


saveRecipeEdit : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
saveRecipeEdit model recipeId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                main
                    |> Page.lenses.main.recipes.get
                    |> DictList.get recipeId
                    |> Maybe.andThen Editing.extractUpdate
                    |> Maybe.Extra.unwrap
                        Cmd.none
                        (RecipeUpdateClientInput.to
                            >> (\recipeUpdate ->
                                    Requests.saveRecipe
                                        { authorizedAccess =
                                            { configuration = model.configuration
                                            , jwt = main.jwt
                                            }
                                        , recipeUpdate = recipeUpdate
                                        }
                               )
                        )
            )
    )


gotSaveRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotSaveRecipeResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipe ->
                model
                    |> mapRecipeStateById recipe.id
                        (always (Editing.asView recipe))
            )
    , Cmd.none
    )


enterEditRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
enterEditRecipe model recipeId =
    ( model
        |> mapRecipeStateById recipeId
            (Editing.toUpdate RecipeUpdateClientInput.from)
    , Cmd.none
    )


exitEditRecipeAt : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
exitEditRecipeAt model recipeId =
    ( model |> mapRecipeStateById recipeId Editing.toView
    , Cmd.none
    )


requestDeleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
requestDeleteRecipe model recipeId =
    ( model |> mapRecipeStateById recipeId Editing.toDelete
    , Cmd.none
    )


confirmDeleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteRecipe model recipeId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteRecipe
                    { authorizedAccess =
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                    , recipeId = recipeId
                    }
            )
    )


cancelDeleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteRecipe model recipeId =
    ( model |> mapRecipeStateById recipeId Editing.toView
    , Cmd.none
    )


gotDeleteRecipeResponse : Page.Model -> RecipeId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteRecipeResponse model deletedId dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model)
            (always
                (model
                    |> Tristate.mapMain (LensUtil.deleteAtId deletedId Page.lenses.main.recipes)
                )
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model
        |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.searchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.recipes
                }
                string
            )
    , Cmd.none
    )


mapRecipeStateById : RecipeId -> (Page.RecipeState -> Page.RecipeState) -> Page.Model -> Page.Model
mapRecipeStateById recipeId =
    LensUtil.updateById recipeId Page.lenses.main.recipes
        >> Tristate.mapMain
