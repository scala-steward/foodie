module Pages.ComplexFoods.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional as Optional
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.ComplexFoods.Pagination as Pagination
import Pages.ComplexFoods.Requests as Requests
import Pages.ComplexFoods.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Result.Extra
import Util.Editing as Editing
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , recipes = Dict.empty
      , complexFoods = Dict.empty
      , complexFoodsToCreate = Dict.empty
      , recipesSearchString = ""
      , complexFoodsSearchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
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
        |> (Page.lenses.complexFoodsToCreate
                |> Compose.lensWithOptional (LensUtil.dictByKey complexFoodClientInput.recipeId)
           ).set
            complexFoodClientInput
    , Cmd.none
    )


createComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
createComplexFood model recipeId =
    ( model
    , model
        |> (Page.lenses.complexFoodsToCreate
                |> Compose.lensWithOptional (LensUtil.dictByKey recipeId)
           ).getOption
        |> Maybe.Extra.unwrap Cmd.none
            (ComplexFoodClientInput.to
                >> Requests.createComplexFood model.authorizedAccess
            )
    )


gotCreateComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotCreateComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFood ->
                model
                    |> LensUtil.insertAtId complexFood.recipeId Page.lenses.complexFoods (complexFood |> Editing.asView)
                    |> LensUtil.deleteAtId complexFood.recipeId Page.lenses.complexFoodsToCreate
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
    , complexFoodClientInput
        |> ComplexFoodClientInput.to
        |> Requests.updateComplexFood model.authorizedAccess
    )


gotSaveComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotSaveComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFood ->
                model
                    |> mapComplexFoodStateByRecipeId complexFood.recipeId (always complexFood >> Editing.asView)
                    |> LensUtil.deleteAtId complexFood.recipeId Page.lenses.complexFoodsToCreate
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
    , Requests.deleteComplexFood model.authorizedAccess complexFoodId
    )


cancelDeleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteComplexFood model complexFoodId =
    ( model |> mapComplexFoodStateByRecipeId complexFoodId Editing.toView
    , Cmd.none
    )


gotDeleteComplexFoodResponse : Page.Model -> ComplexFoodId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteComplexFoodResponse model complexFoodId result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (always
                (model
                    |> LensUtil.deleteAtId complexFoodId Page.lenses.complexFoods
                )
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\recipes ->
                model
                    |> Page.lenses.recipes.set (recipes |> List.map (\r -> ( r.id, r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipes).set True
            )
    , Cmd.none
    )


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFoods ->
                model
                    |> Page.lenses.complexFoods.set (complexFoods |> List.map (\r -> ( r.recipeId, r |> Editing.asView )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFoods).set True
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> Recipe -> ( Page.Model, Cmd Page.Msg )
selectRecipe model recipe =
    ( model
        |> LensUtil.insertAtId recipe.id
            Page.lenses.complexFoodsToCreate
            (ComplexFoodClientInput.default recipe.id)
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> LensUtil.deleteAtId recipeId Page.lenses.complexFoodsToCreate
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setRecipesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens = Page.lenses.recipesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.recipes
        }
        model
        string
    , Cmd.none
    )


setComplexFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setComplexFoodsSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens = Page.lenses.complexFoodsSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.complexFoods
        }
        model
        string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination.Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model
        |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapComplexFoodStateByRecipeId : ComplexFoodId -> (Page.ComplexFoodState -> Page.ComplexFoodState) -> Page.Model -> Page.Model
mapComplexFoodStateByRecipeId recipeId =
    Page.lenses.complexFoods
        |> Compose.lensWithOptional (LensUtil.dictByKey recipeId)
        |> Optional.modify


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
