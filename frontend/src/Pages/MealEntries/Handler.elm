module Pages.MealEntries.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Page as Page exposing (Msg(..))
import Pages.MealEntries.Pagination as Pagination exposing (Pagination)
import Pages.MealEntries.Requests as Requests
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
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
    )


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.Msg
initialFetch authorizedAccess mealId =
    Cmd.batch
        [ Requests.fetchMeal { authorizedAccess = authorizedAccess, mealId = mealId }
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

        Page.UpdateMeal mealUpdateClientInput ->
            updateMeal model mealUpdateClientInput

        Page.SaveMealEdit ->
            saveMealEdit model

        Page.GotSaveMealResponse result ->
            gotSaveMealResponse model result

        Page.EnterEditMeal ->
            enterEditMeal model

        Page.ExitEditMeal ->
            exitEditMeal model

        Page.RequestDeleteMeal ->
            requestDeleteMeal model

        Page.ConfirmDeleteMeal ->
            confirmDeleteMeal model

        Page.CancelDeleteMeal ->
            cancelDeleteMeal model

        Page.GotDeleteMealResponse result ->
            gotDeleteMealResponse model result


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


gotSaveMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotSaveMealEntryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\mealEntry ->
                model
                    |> mapMealEntryStateById mealEntry.id
                        (mealEntry |> Editing.asView |> always)
                    |> Tristate.mapMain (LensUtil.deleteAtId mealEntry.recipeId Page.lenses.main.mealEntriesToAdd)
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


cancelDeleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteMealEntry model mealEntryId =
    ( model |> mapMealEntryStateById mealEntryId Editing.toView
    , Cmd.none
    )


gotDeleteMealEntryResponse : Page.Model -> MealEntryId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteMealEntryResponse model mealEntryId result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\_ ->
                model
                    |> Tristate.mapMain (LensUtil.deleteAtId mealEntryId Page.lenses.main.mealEntries)
            )
    , Cmd.none
    )


gotFetchMealEntriesResponse : Page.Model -> Result Error (List MealEntry) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealEntriesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\mealEntries ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.mealEntries.set (mealEntries |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .id) |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\recipes ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.recipes.set (recipes |> DictList.fromListWithKey .id |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotFetchMealResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\meal ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.meal.set (meal |> Editing.asView |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
selectRecipe model recipeId =
    ( model
        |> Tristate.mapMain
            (\main ->
                main
                    |> LensUtil.insertAtId recipeId
                        Page.lenses.main.mealEntriesToAdd
                        (MealEntryCreationClientInput.default main.meal.original.id recipeId)
            )
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> Tristate.mapMain (LensUtil.deleteAtId recipeId Page.lenses.main.mealEntriesToAdd)
    , Cmd.none
    )


addRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
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


gotAddMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotAddMealEntryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\mealEntry ->
                model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId mealEntry.id Page.lenses.main.mealEntries (mealEntry |> Editing.asView)
                            >> LensUtil.deleteAtId mealEntry.recipeId Page.lenses.main.mealEntriesToAdd
                        )
            )
    , Cmd.none
    )


updateAddRecipe : Page.Model -> MealEntryCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddRecipe model mealEntryCreationClientInput =
    ( model
        |> Tristate.mapMain (LensUtil.updateById mealEntryCreationClientInput.recipeId Page.lenses.main.mealEntriesToAdd (always mealEntryCreationClientInput))
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setRecipesSearchString model string =
    ( model
        |> Tristate.mapMain
            (\main ->
                PaginationSettings.setSearchStringAndReset
                    { searchStringLens =
                        Page.lenses.main.recipesSearchString
                    , paginationSettingsLens =
                        Page.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.recipes
                    }
                    main
                    string
            )
    , Cmd.none
    )


setEntriesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setEntriesSearchString model string =
    ( model
        |> Tristate.mapMain
            (\main ->
                PaginationSettings.setSearchStringAndReset
                    { searchStringLens =
                        Page.lenses.main.entriesSearchString
                    , paginationSettingsLens =
                        Page.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.mealEntries
                    }
                    main
                    string
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


updateMeal : Page.Model -> MealUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateMeal model mealUpdateClientInput =
    ( model
        |> Tristate.mapMain
            ((Page.lenses.main.meal
                |> Compose.lensWithOptional Editing.lenses.update
             ).set
                mealUpdateClientInput
            )
    , Cmd.none
    )


saveMealEdit : Page.Model -> ( Page.Model, Cmd Page.Msg )
saveMealEdit model =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> Page.lenses.main.meal.get
                    |> Editing.extractUpdate
                    |> Maybe.andThen MealUpdateClientInput.to
                    |> Maybe.map
                        (\mealUpdate ->
                            Pages.Util.Requests.saveMealWith
                                Page.GotSaveMealResponse
                                { authorizedAccess =
                                    { configuration = model.configuration
                                    , jwt = main.jwt
                                    }
                                , mealUpdate = mealUpdate
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotSaveMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotSaveMealResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\meal ->
                model
                    |> Tristate.mapMain (Page.lenses.main.meal.set (meal |> Editing.asView))
            )
    , Cmd.none
    )


enterEditMeal : Page.Model -> ( Page.Model, Cmd Page.Msg )
enterEditMeal model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.meal (Editing.toUpdate MealUpdateClientInput.from))
    , Cmd.none
    )


exitEditMeal : Page.Model -> ( Page.Model, Cmd Page.Msg )
exitEditMeal model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.meal Editing.toView)
    , Cmd.none
    )


requestDeleteMeal : Page.Model -> ( Page.Model, Cmd Msg )
requestDeleteMeal model =
    ( model |> Tristate.mapMain (Lens.modify Page.lenses.main.meal Editing.toDelete)
    , Cmd.none
    )


confirmDeleteMeal : Page.Model -> ( Page.Model, Cmd Msg )
confirmDeleteMeal model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Pages.Util.Requests.deleteMealWith Page.GotDeleteMealResponse
                    { authorizedAccess =
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                    , mealId = main.meal.original.id
                    }
            )
    )


cancelDeleteMeal : Page.Model -> ( Page.Model, Cmd Page.Msg )
cancelDeleteMeal model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.meal Editing.toView)
    , Cmd.none
    )


gotDeleteMealResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteMealResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model.configuration error, Cmd.none ))
            (\_ ->
                ( model
                , Links.loadFrontendPage
                    model.configuration
                    (() |> Addresses.Frontend.meals.address)
                )
            )


mapMealEntryStateById : MealEntryId -> (Page.MealEntryState -> Page.MealEntryState) -> Page.Model -> Page.Model
mapMealEntryStateById mealEntryId =
    LensUtil.updateById mealEntryId Page.lenses.main.mealEntries
        >> Tristate.mapMain
