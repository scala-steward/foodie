module Pages.MealEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional as Optional
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.MealInfo as MealInfo
import Pages.MealEntries.Page as Page exposing (Msg(..))
import Pages.MealEntries.Pagination as Pagination exposing (Pagination)
import Pages.MealEntries.Requests as Requests
import Pages.MealEntries.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Result.Extra
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , mealId = flags.mealId
      , mealInfo = Nothing
      , mealEntries = Dict.empty
      , recipes = Dict.empty
      , recipesSearchString = ""
      , entriesSearchString = ""
      , mealEntriesToAdd = Dict.empty
      , initialization = Loading Status.initial
      , pagination = Pagination.initial
      }
    , initialFetch
        flags.authorizedAccess
        flags.mealId
    )


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.Msg
initialFetch authorizedAccess mealId =
    Cmd.batch
        [ Requests.fetchMeal authorizedAccess mealId
        , Requests.fetchRecipes authorizedAccess
        , Requests.fetchMealEntries authorizedAccess mealId
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateMealEntry mealEntryUpdateClientInput ->
            updateMealEntry model mealEntryUpdateClientInput

        Page.SaveMealEntryEdit mealEntryUpdateClientInput ->
            saveMealEntryEdit model mealEntryUpdateClientInput

        Page.GotSaveMealEntryResponse result ->
            gotSaveMealEntryResponse model result

        Page.EnterEditMealEntry mealEntryId ->
            enterEditMealEntry model mealEntryId

        Page.ExitEditMealEntryAt mealEntryId ->
            exitEditMealEntryAt model mealEntryId

        Page.RequestDeleteMealEntry mealEntryId ->
            requestDeleteMealEntry model mealEntryId

        Page.ConfirmDeleteMealEntry mealEntryId ->
            confirmDeleteMealEntry model mealEntryId

        Page.CancelDeleteMealEntry mealEntryId ->
            cancelDeleteMealEntry model mealEntryId

        Page.GotDeleteMealEntryResponse mealEntryId result ->
            gotDeleteMealEntryResponse model mealEntryId result

        Page.GotFetchMealEntriesResponse result ->
            gotFetchMealEntriesResponse model result

        Page.GotFetchRecipesResponse result ->
            gotFetchRecipesResponse model result

        Page.GotFetchMealResponse result ->
            gotFetchMealResponse model result

        Page.SelectRecipe recipe ->
            selectRecipe model recipe

        Page.DeselectRecipe recipeId ->
            deselectRecipe model recipeId

        Page.AddRecipe recipeId ->
            addRecipe model recipeId

        Page.GotAddMealEntryResponse result ->
            gotAddMealEntryResponse model result

        Page.UpdateAddRecipe mealEntryCreationClientInput ->
            updateAddRecipe model mealEntryCreationClientInput

        Page.SetRecipesSearchString string ->
            setRecipesSearchString model string

        Page.SetEntriesSearchString string ->
            setEntriesSearchString model string

        Page.SetPagination pagination ->
            setPagination model pagination


updateMealEntry : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateMealEntry model mealEntryUpdateClientInput =
    ( model
        |> mapMealEntryStateById mealEntryUpdateClientInput.mealEntryId
            (Editing.lenses.update.set mealEntryUpdateClientInput)
    , Cmd.none
    )


saveMealEntryEdit : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveMealEntryEdit model mealEntryUpdateClientInput =
    ( model
    , mealEntryUpdateClientInput
        |> MealEntryUpdateClientInput.to
        |> Requests.saveMealEntry model.authorizedAccess
    )


gotSaveMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotSaveMealEntryResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\mealEntry ->
                model
                    |> mapMealEntryStateById mealEntry.id
                        (mealEntry |> Editing.asView |> always)
                    |> LensUtil.deleteAtId mealEntry.recipeId Page.lenses.mealEntriesToAdd
            )
    , Cmd.none
    )


enterEditMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
enterEditMealEntry model mealEntryId =
    ( model
        |> mapMealEntryStateById mealEntryId
            (Editing.toUpdate MealEntryUpdateClientInput.from)
    , Cmd.none
    )


exitEditMealEntryAt : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
exitEditMealEntryAt model mealEntryId =
    ( model
        |> mapMealEntryStateById mealEntryId Editing.toView
    , Cmd.none
    )


requestDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
requestDeleteMealEntry model mealEntryId =
    ( model |> mapMealEntryStateById mealEntryId Editing.toDelete
    , Cmd.none
    )


confirmDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteMealEntry model mealEntryId =
    ( model
    , Requests.deleteMealEntry model.authorizedAccess mealEntryId
    )


cancelDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteMealEntry model mealEntryId =
    ( model |> mapMealEntryStateById mealEntryId Editing.toView
    , Cmd.none
    )


gotDeleteMealEntryResponse : Page.Model -> MealEntryId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteMealEntryResponse model mealEntryId result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\_ ->
                model
                    |> LensUtil.deleteAtId mealEntryId Page.lenses.mealEntries
            )
    , Cmd.none
    )


gotFetchMealEntriesResponse : Page.Model -> Result Error (List MealEntry) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealEntriesResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\mealEntries ->
                model
                    |> Page.lenses.mealEntries.set (mealEntries |> List.map (\mealEntry -> ( mealEntry.id, mealEntry |> Editing.asView )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.mealEntries).set True
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


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotFetchMealResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\meal ->
                model
                    |> Page.lenses.mealInfo.set (meal |> MealInfo.from |> Just)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meal).set True
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
selectRecipe model recipeId =
    ( model
        |> LensUtil.insertAtId recipeId
            Page.lenses.mealEntriesToAdd
            (MealEntryCreationClientInput.default model.mealId recipeId)
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> LensUtil.deleteAtId recipeId Page.lenses.mealEntriesToAdd
    , Cmd.none
    )


addRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
addRecipe model recipeId =
    ( model
    , Dict.get recipeId model.mealEntriesToAdd
        |> Maybe.map
            (MealEntryCreationClientInput.toCreation
                >> Requests.addMealEntry model.authorizedAccess
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotAddMealEntryResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\mealEntry ->
                model
                    |> LensUtil.insertAtId mealEntry.id Page.lenses.mealEntries (mealEntry |> Editing.asView)
                    |> LensUtil.deleteAtId mealEntry.recipeId Page.lenses.mealEntriesToAdd
            )
    , Cmd.none
    )


updateAddRecipe : Page.Model -> MealEntryCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddRecipe model mealEntryCreationClientInput =
    ( model
        |> Optional.modify (Page.lenses.mealEntriesToAdd |> Compose.lensWithOptional (LensUtil.dictByKey mealEntryCreationClientInput.recipeId))
            (always mealEntryCreationClientInput)
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setRecipesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.recipesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.recipes
        }
        model
        string
    , Cmd.none
    )


setEntriesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setEntriesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.entriesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.mealEntries
        }
        model
        string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapMealEntryStateById : MealEntryId -> (Page.MealEntryState -> Page.MealEntryState) -> Page.Model -> Page.Model
mapMealEntryStateById mealEntryId =
    Page.lenses.mealEntries
        |> LensUtil.updateById mealEntryId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization