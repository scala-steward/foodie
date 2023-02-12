module Pages.ComplexFoods.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Compose as Compose
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
    )


initialFetch : AuthorizedAccess -> Cmd Page.Msg
initialFetch authorizedAccess =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchComplexFoods authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateComplexFoodCreation createComplexFoodsMap ->
            updateComplexFoodCreation model createComplexFoodsMap

        Page.CreateComplexFood recipeId ->
            createComplexFood model recipeId

        Page.GotCreateComplexFoodResponse result ->
            gotCreateComplexFoodResponse model result

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

        Page.SelectRecipe recipe ->
            selectRecipe model recipe

        Page.DeselectRecipe recipeId ->
            deselectRecipe model recipeId

        Page.SetRecipesSearchString string ->
            setRecipesSearchString model string

        Page.SetComplexFoodsSearchString string ->
            setComplexFoodsSearchString model string

        Page.SetPagination pagination ->
            setPagination model pagination


updateComplexFoodCreation : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.Msg )
updateComplexFoodCreation model complexFoodClientInput =
    ( model
        |> Tristate.mapMain
            ((Page.lenses.main.complexFoodsToCreate
                |> Compose.lensWithOptional (LensUtil.dictByKey complexFoodClientInput.recipeId)
             ).set
                complexFoodClientInput
            )
    , Cmd.none
    )


createComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
createComplexFood model recipeId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> (Page.lenses.main.complexFoodsToCreate
                            |> Compose.lensWithOptional (LensUtil.dictByKey recipeId)
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


gotCreateComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotCreateComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\complexFood ->
                model
                    |> Tristate.mapMain (LensUtil.insertAtId complexFood.recipeId Page.lenses.main.complexFoods (complexFood |> Editing.asView))
                    |> Tristate.mapMain (LensUtil.deleteAtId complexFood.recipeId Page.lenses.main.complexFoodsToCreate)
            )
    , Cmd.none
    )


updateComplexFood : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.Msg )
updateComplexFood model complexFoodClientInput =
    ( model
        |> mapComplexFoodStateByRecipeId complexFoodClientInput.recipeId
            (Editing.lenses.update.set complexFoodClientInput)
    , Cmd.none
    )


saveComplexFoodEdit : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.Msg )
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


gotSaveComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotSaveComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\complexFood ->
                model
                    |> mapComplexFoodStateByRecipeId complexFood.recipeId (always complexFood >> Editing.asView)
                    |> Tristate.mapMain (LensUtil.deleteAtId complexFood.recipeId Page.lenses.main.complexFoodsToCreate)
            )
    , Cmd.none
    )


enterEditComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
enterEditComplexFood model complexFoodId =
    ( model
        |> mapComplexFoodStateByRecipeId complexFoodId
            (Editing.toUpdate ComplexFoodClientInput.from)
    , Cmd.none
    )


exitEditComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
exitEditComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toView
    , Cmd.none
    )


requestDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
requestDeleteComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toDelete
    , Cmd.none
    )


confirmDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
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


cancelDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toView
    , Cmd.none
    )


gotDeleteComplexFoodResponse : Page.Model -> ComplexFoodId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteComplexFoodResponse model complexFoodId result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (always
                (model
                    |> Tristate.mapMain (LensUtil.deleteAtId complexFoodId Page.lenses.main.complexFoods)
                )
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\recipes ->
                model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.recipes.set (recipes |> DictList.fromListWithKey .id |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\complexFoods ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.complexFoods.set (complexFoods |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .recipeId) |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> Recipe -> ( Page.Model, Cmd Page.Msg )
selectRecipe model recipe =
    ( model
        |> Tristate.mapMain
            (LensUtil.insertAtId recipe.id
                Page.lenses.main.complexFoodsToCreate
                (ComplexFoodClientInput.default recipe.id)
            )
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> Tristate.mapMain (LensUtil.deleteAtId recipeId Page.lenses.main.complexFoodsToCreate)
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setRecipesSearchString model string =
    ( model
        |> Tristate.mapMain
            (\main ->
                PaginationSettings.setSearchStringAndReset
                    { searchStringLens = Page.lenses.main.recipesSearchString
                    , paginationSettingsLens =
                        Page.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.recipes
                    }
                    main
                    string
            )
    , Cmd.none
    )


setComplexFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setComplexFoodsSearchString model string =
    ( model
        |> Tristate.mapMain
            (\main ->
                PaginationSettings.setSearchStringAndReset
                    { searchStringLens = Page.lenses.main.complexFoodsSearchString
                    , paginationSettingsLens =
                        Page.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.complexFoods
                    }
                    main
                    string
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination.Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model
        |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


mapComplexFoodStateByRecipeId : ComplexFoodId -> (Page.ComplexFoodState -> Page.ComplexFoodState) -> Page.Model -> Page.Model
mapComplexFoodStateByRecipeId recipeId =
    LensUtil.updateById recipeId Page.lenses.main.complexFoods
        >> Tristate.mapMain
