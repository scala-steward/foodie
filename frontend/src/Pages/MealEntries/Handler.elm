module Pages.MealEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional
import Pages.MealEntries.Meal.Handler
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Page as Page exposing (LogicMsg(..))
import Pages.MealEntries.Pagination as Pagination exposing (Pagination)
import Pages.MealEntries.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch
        flags.authorizedAccess
        flags.mealId
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess mealId =
    Cmd.batch
        [ Pages.MealEntries.Meal.Handler.initialFetch authorizedAccess mealId |> Cmd.map Page.MealMsg
        , Requests.fetchRecipes authorizedAccess
        , Requests.fetchMealEntries authorizedAccess mealId
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
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

        Page.MealMsg mealMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.meal
                , mainSubModelLens = Page.lenses.main.meal
                , subModelOf = Page.mealSubModel
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.MealEntries.Meal.Handler.updateLogic
                , toMsg = Page.MealMsg
                }
                mealMsg
                model


updateMealEntry : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateMealEntry model mealEntryUpdateClientInput =
    ( model
        |> mapMealEntryStateById mealEntryUpdateClientInput.mealEntryId
            (Editing.lenses.update.set mealEntryUpdateClientInput)
    , Cmd.none
    )


saveMealEntryEdit : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
saveMealEntryEdit model mealEntryUpdateClientInput =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                mealEntryUpdateClientInput
                    |> MealEntryUpdateClientInput.to
                    |> Requests.saveMealEntry
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
            )
    )


gotSaveMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.LogicMsg )
gotSaveMealEntryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\mealEntry ->
                model
                    |> mapMealEntryStateById mealEntry.id
                        (mealEntry |> Editing.asView |> always)
                    |> Tristate.mapMain (LensUtil.deleteAtId mealEntry.recipeId Page.lenses.main.mealEntriesToAdd)
            )
    , Cmd.none
    )


enterEditMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.LogicMsg )
enterEditMealEntry model mealEntryId =
    ( model
        |> mapMealEntryStateById mealEntryId
            (Editing.toUpdate MealEntryUpdateClientInput.from)
    , Cmd.none
    )


exitEditMealEntryAt : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.LogicMsg )
exitEditMealEntryAt model mealEntryId =
    ( model
        |> mapMealEntryStateById mealEntryId Editing.toView
    , Cmd.none
    )


requestDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteMealEntry model mealEntryId =
    ( model |> mapMealEntryStateById mealEntryId Editing.toDelete
    , Cmd.none
    )


confirmDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteMealEntry model mealEntryId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteMealEntry
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    mealEntryId
            )
    )


cancelDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteMealEntry model mealEntryId =
    ( model |> mapMealEntryStateById mealEntryId Editing.toView
    , Cmd.none
    )


gotDeleteMealEntryResponse : Page.Model -> MealEntryId -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteMealEntryResponse model mealEntryId result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\_ ->
                model
                    |> Tristate.mapMain (LensUtil.deleteAtId mealEntryId Page.lenses.main.mealEntries)
            )
    , Cmd.none
    )


gotFetchMealEntriesResponse : Page.Model -> Result Error (List MealEntry) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchMealEntriesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\mealEntries ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.mealEntries.set (mealEntries |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .id) |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchRecipesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipes ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.recipes.set (recipes |> DictList.fromListWithKey .id |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.LogicMsg )
selectRecipe model recipeId =
    ( model
        |> Tristate.mapMain
            (\main ->
                main
                    |> LensUtil.insertAtId recipeId
                        Page.lenses.main.mealEntriesToAdd
                        (MealEntryCreationClientInput.default main.meal.parent.original.id recipeId)
            )
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.LogicMsg )
deselectRecipe model recipeId =
    ( model
        |> Tristate.mapMain (LensUtil.deleteAtId recipeId Page.lenses.main.mealEntriesToAdd)
    , Cmd.none
    )


addRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.LogicMsg )
addRecipe model recipeId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                DictList.get recipeId main.mealEntriesToAdd
                    |> Maybe.map
                        (MealEntryCreationClientInput.toCreation
                            >> Requests.addMealEntry
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.LogicMsg )
gotAddMealEntryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\mealEntry ->
                model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId mealEntry.id Page.lenses.main.mealEntries (mealEntry |> Editing.asView)
                            >> LensUtil.deleteAtId mealEntry.recipeId Page.lenses.main.mealEntriesToAdd
                        )
            )
    , Cmd.none
    )


updateAddRecipe : Page.Model -> MealEntryCreationClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateAddRecipe model mealEntryCreationClientInput =
    ( model
        |> Tristate.mapMain (LensUtil.updateById mealEntryCreationClientInput.recipeId Page.lenses.main.mealEntriesToAdd (always mealEntryCreationClientInput))
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setRecipesSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.recipesSearchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.recipes
                }
                string
            )
    , Cmd.none
    )


setEntriesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setEntriesSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.entriesSearchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.mealEntries
                }
                string
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


mapMealEntryStateById : MealEntryId -> (Page.MealEntryState -> Page.MealEntryState) -> Page.Model -> Page.Model
mapMealEntryStateById mealEntryId =
    LensUtil.updateById mealEntryId Page.lenses.main.mealEntries
        >> Tristate.mapMain
