module Pages.ComplexFoods.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.ComplexFoods.Pagination as Pagination
import Pages.ComplexFoods.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing
import Util.HttpUtil exposing (Error)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> Cmd Page.LogicMsg
initialFetch authorizedAccess =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchComplexFoods authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.UpdateComplexFoodCreation createComplexFoodsMap ->
            updateComplexFoodCreation model createComplexFoodsMap

        Page.CreateComplexFood recipeId ->
            createComplexFood model recipeId

        Page.GotCreateComplexFoodResponse result ->
            gotCreateComplexFoodResponse model result

        Page.ToggleComplexFoodControls complexFoodId ->
            toggleComplexFoodControls model complexFoodId

        Page.UpdateComplexFood complexFoodClientInput ->
            updateComplexFood model complexFoodClientInput

        Page.SaveComplexFoodEdit complexFoodClientInput ->
            saveComplexFoodEdit model complexFoodClientInput

        Page.GotSaveComplexFoodResponse result ->
            gotSaveComplexFoodResponse model result

        Page.EnterEditComplexFood complexFoodId ->
            enterEditComplexFood model complexFoodId

        Page.ExitEditComplexFood complexFoodId ->
            exitEditComplexFood model complexFoodId

        Page.RequestDeleteComplexFood complexFoodId ->
            requestDeleteComplexFood model complexFoodId

        Page.ConfirmDeleteComplexFood complexFoodId ->
            confirmDeleteComplexFood model complexFoodId

        Page.CancelDeleteComplexFood complexFoodId ->
            cancelDeleteComplexFood model complexFoodId

        Page.GotDeleteComplexFoodResponse complexFoodId result ->
            gotDeleteComplexFoodResponse model complexFoodId result

        Page.GotFetchRecipesResponse result ->
            gotFetchRecipesResponse model result

        Page.GotFetchComplexFoodsResponse result ->
            gotFetchComplexFoodsResponse model result

        Page.ToggleRecipeControls recipeId ->
            toggleRecipeControls model recipeId

        Page.SelectRecipe recipeId ->
            selectRecipe model recipeId

        Page.DeselectRecipe recipeId ->
            deselectRecipe model recipeId

        Page.SetRecipesSearchString string ->
            setRecipesSearchString model string

        Page.SetComplexFoodsSearchString string ->
            setComplexFoodsSearchString model string

        Page.SetPagination pagination ->
            setPagination model pagination


updateComplexFoodCreation : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateComplexFoodCreation model complexFoodClientInput =
    ( model
        |> mapRecipeStateById complexFoodClientInput.recipeId
            (Editing.lenses.update.set complexFoodClientInput)
    , Cmd.none
    )


createComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
createComplexFood model recipeId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> (Page.lenses.main.complexFoods
                            |> Compose.lensWithOptional (LensUtil.dictByKey recipeId)
                            |> Compose.optionalWithOptional Editing.lenses.update
                       ).getOption
                    |> Maybe.map
                        (ComplexFoodClientInput.to
                            >> Requests.createComplexFood
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotCreateComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.LogicMsg )
gotCreateComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexFood ->
                model
                    |> Tristate.mapMain (LensUtil.insertAtId complexFood.recipeId Page.lenses.main.complexFoods (complexFood |> Editing.asView))
            )
    , Cmd.none
    )


toggleComplexFoodControls : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
toggleComplexFoodControls model complexFoodId =
    ( model
        |> mapComplexFoodStateByRecipeId complexFoodId Editing.toggleControls
    , Cmd.none
    )


updateComplexFood : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateComplexFood model complexFoodClientInput =
    ( model
        |> mapComplexFoodStateByRecipeId complexFoodClientInput.recipeId
            (Editing.lenses.update.set complexFoodClientInput)
    , Cmd.none
    )


saveComplexFoodEdit : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.LogicMsg )
saveComplexFoodEdit model complexFoodClientInput =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                complexFoodClientInput
                    |> ComplexFoodClientInput.to
                    |> Requests.updateComplexFood
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
            )
    )


gotSaveComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.LogicMsg )
gotSaveComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexFood ->
                model
                    |> mapComplexFoodStateByRecipeId complexFood.recipeId (always complexFood >> Editing.asView)
            )
    , Cmd.none
    )


enterEditComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
enterEditComplexFood model complexFoodId =
    ( model
        |> mapComplexFoodStateByRecipeId complexFoodId
            (Editing.toUpdate ComplexFoodClientInput.from)
    , Cmd.none
    )


exitEditComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
exitEditComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toView
    , Cmd.none
    )


requestDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toDelete
    , Cmd.none
    )


confirmDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteComplexFood model complexFoodId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteComplexFood
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    complexFoodId
            )
    )


cancelDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toView
    , Cmd.none
    )


gotDeleteComplexFoodResponse : Page.Model -> ComplexFoodId -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteComplexFoodResponse model complexFoodId result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (always
                (model
                    |> Tristate.mapMain (LensUtil.deleteAtId complexFoodId Page.lenses.main.complexFoods)
                )
            )
    , Cmd.none
    )



--todo: Check back for duplication - exactly the same implementation as in Recipes.Handler


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchRecipesResponse model result =
    ( result
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


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexFoods ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.complexFoods.set (complexFoods |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .recipeId) |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


toggleRecipeControls : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.LogicMsg )
toggleRecipeControls model recipeId =
    ( model
        |> mapRecipeStateById recipeId Editing.toggleControls
    , Cmd.none
    )


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.LogicMsg )
selectRecipe model recipeId =
    ( model
        |> mapRecipeStateById recipeId (ComplexFoodClientInput.withSuggestion |> Editing.toUpdate)
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.LogicMsg )
deselectRecipe model recipeId =
    ( model
        |> mapRecipeStateById recipeId Editing.toView
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setRecipesSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens = Page.lenses.main.recipesSearchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.recipes
                }
                string
            )
    , Cmd.none
    )


setComplexFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setComplexFoodsSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens = Page.lenses.main.complexFoodsSearchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.complexFoods
                }
                string
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination.Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setPagination model pagination =
    ( model
        |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


mapComplexFoodStateByRecipeId : ComplexFoodId -> (Page.ComplexFoodState -> Page.ComplexFoodState) -> Page.Model -> Page.Model
mapComplexFoodStateByRecipeId recipeId =
    LensUtil.updateById recipeId Page.lenses.main.complexFoods
        >> Tristate.mapMain


mapRecipeStateById : RecipeId -> (Page.RecipeState -> Page.RecipeState) -> Page.Model -> Page.Model
mapRecipeStateById recipeId =
    LensUtil.updateById recipeId Page.lenses.main.recipes
        >> Tristate.mapMain
