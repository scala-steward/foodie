module Pages.Meals.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal)
import Monocle.Compose as Compose
import Monocle.Optional
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Pagination as Pagination exposing (Pagination)
import Pages.Meals.Requests as Requests
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
    , Requests.fetchMeals flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.UpdateMealCreation mealCreationClientInput ->
            updateMealCreation model mealCreationClientInput

        Page.CreateMeal ->
            createMeal model

        Page.GotCreateMealResponse dataOrError ->
            gotCreateMealResponse model dataOrError

        Page.UpdateMeal mealUpdateClientInput ->
            updateMeal model mealUpdateClientInput

        Page.SaveMealEdit mealId ->
            saveMealEdit model mealId

        Page.GotSaveMealResponse dataOrError ->
            gotSaveMealResponse model dataOrError

        Page.ToggleControls mealId ->
            toggleControls model mealId

        Page.EnterEditMeal mealId ->
            enterEditMeal model mealId

        Page.ExitEditMealAt mealId ->
            exitEditMealAt model mealId

        Page.RequestDeleteMeal mealId ->
            requestDeleteMeal model mealId

        Page.ConfirmDeleteMeal mealId ->
            confirmDeleteMeal model mealId

        Page.CancelDeleteMeal mealId ->
            cancelDeleteMeal model mealId

        Page.GotDeleteMealResponse deletedId dataOrError ->
            gotDeleteMealResponse model deletedId dataOrError

        Page.GotFetchMealsResponse dataOrError ->
            gotFetchMealsResponse model dataOrError

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.SetSearchString string ->
            setSearchString model string


updateMealCreation : Page.Model -> Maybe MealCreationClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateMealCreation model mealToAdd =
    ( model
        |> Tristate.mapMain (Page.lenses.main.mealToAdd.set mealToAdd)
    , Cmd.none
    )


createMeal : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
createMeal model =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main.mealToAdd
                    |> Maybe.andThen MealCreationClientInput.toCreation
                    |> Maybe.map
                        (Requests.createMeal
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotCreateMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd msg )
gotCreateMealResponse model dataOrError =
    dataOrError
        |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
            (\meal ->
                ( model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId meal.id Page.lenses.main.meals (meal |> Editing.asView)
                            >> Page.lenses.main.mealToAdd.set Nothing
                        )
                , meal.id
                    |> Addresses.Frontend.mealEntryEditor.address
                    |> Links.loadFrontendPage model.configuration
                )
            )


updateMeal : Page.Model -> MealUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateMeal model mealUpdateClientInput =
    ( model
        |> mapMealStateById mealUpdateClientInput.id
            (Editing.lenses.update.set mealUpdateClientInput)
    , Cmd.none
    )


saveMealEdit : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
saveMealEdit model mealId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> Page.lenses.main.meals.get
                    |> DictList.get mealId
                    |> Maybe.andThen Editing.extractUpdate
                    |> Maybe.andThen MealUpdateClientInput.to
                    |> Maybe.map
                        (\mealUpdate ->
                            Requests.saveMeal
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


gotSaveMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.LogicMsg )
gotSaveMealResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model)
            (\meal ->
                model
                    |> mapMealStateById meal.id
                        (meal |> Editing.asViewWithElement)
            )
    , Cmd.none
    )

toggleControls : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
toggleControls model mealId =
    ( model
        |> mapMealStateById mealId Editing.toggleControls
    , Cmd.none
    )

enterEditMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
enterEditMeal model mealId =
    ( model
        |> mapMealStateById mealId
            (Editing.toUpdate MealUpdateClientInput.from)
    , Cmd.none
    )


exitEditMealAt : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
exitEditMealAt model mealId =
    ( model |> mapMealStateById mealId (Editing.toViewWith { showControls = True })
    , Cmd.none
    )


requestDeleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteMeal model mealId =
    ( model |> mapMealStateById mealId Editing.toDelete
    , Cmd.none
    )


confirmDeleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteMeal model mealId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteMeal
                    { authorizedAccess =
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                    , mealId = mealId
                    }
            )
    )


cancelDeleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteMeal model mealId =
    ( model |> mapMealStateById mealId (Editing.toViewWith { showControls = True })
    , Cmd.none
    )


gotDeleteMealResponse : Page.Model -> MealId -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteMealResponse model deletedId dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model)
            (\_ ->
                model
                    |> Tristate.mapMain (LensUtil.deleteAtId deletedId Page.lenses.main.meals)
            )
    , Cmd.none
    )


gotFetchMealsResponse : Page.Model -> Result Error (List Meal) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchMealsResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model)
            (\meals ->
                model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.meals.set
                            (meals
                                |> List.map Editing.asView
                                |> DictList.fromListWithKey (.original >> .id)
                                |> Just
                            )
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.searchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.meals
                }
                string
            )
    , Cmd.none
    )


mapMealStateById : MealId -> (Page.MealState -> Page.MealState) -> Page.Model -> Page.Model
mapMealStateById mealId =
    LensUtil.updateById mealId Page.lenses.main.meals
        >> Tristate.mapMain
