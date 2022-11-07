module Pages.Meals.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Pagination as Pagination exposing (Pagination)
import Pages.Meals.Requests as Requests
import Pages.Meals.Status as Status
import Pages.Util.PaginationSettings as PaginationSettings
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , meals = Dict.empty
      , mealToAdd = Nothing
      , searchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , Requests.fetchMeals flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
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


updateMealCreation : Page.Model -> Maybe MealCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateMealCreation model mealToAdd =
    ( model
        |> Page.lenses.mealToAdd.set mealToAdd
    , Cmd.none
    )


createMeal : Page.Model -> ( Page.Model, Cmd Page.Msg )
createMeal model =
    ( model
    , model.mealToAdd
        |> Maybe.andThen MealCreationClientInput.toCreation
        |> Maybe.Extra.unwrap Cmd.none (Requests.createMeal model.authorizedAccess)
    )


gotCreateMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd msg )
gotCreateMealResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\meal ->
                model
                    |> LensUtil.insertAtId meal.id Page.lenses.meals (meal |> Editing.asView)
                    |> Page.lenses.mealToAdd.set Nothing
            )
    , Cmd.none
    )


updateMeal : Page.Model -> MealUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateMeal model mealUpdateClientInput =
    ( model
        |> mapMealStateById mealUpdateClientInput.id
            (Editing.lenses.update.set mealUpdateClientInput)
    , Cmd.none
    )


saveMealEdit : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
saveMealEdit model mealId =
    ( model
    , model
        |> Page.lenses.meals.get
        |> Dict.get mealId
        |> Maybe.andThen Editing.extractUpdate
        |> Maybe.andThen MealUpdateClientInput.to
        |> Maybe.Extra.unwrap
            Cmd.none
            (Requests.saveMeal model.authorizedAccess)
    )


gotSaveMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotSaveMealResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\meal ->
                model
                    |> mapMealStateById meal.id
                        (meal |> Editing.asView |> always)
            )
    , Cmd.none
    )


enterEditMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
enterEditMeal model mealId =
    ( model
        |> mapMealStateById mealId
            (Editing.toUpdate MealUpdateClientInput.from)
    , Cmd.none
    )


exitEditMealAt : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
exitEditMealAt model mealId =
    ( model |> mapMealStateById mealId Editing.toView
    , Cmd.none
    )


requestDeleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
requestDeleteMeal model mealId =
    ( model |> mapMealStateById mealId Editing.toDelete
    , Cmd.none
    )


confirmDeleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteMeal model mealId =
    ( model
    , Requests.deleteMeal model.authorizedAccess mealId
    )


cancelDeleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteMeal model mealId =
    ( model |> mapMealStateById mealId Editing.toView
    , Cmd.none
    )


gotDeleteMealResponse : Page.Model -> MealId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteMealResponse model deletedId dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\_ ->
                model
                    |> LensUtil.deleteAtId deletedId Page.lenses.meals
            )
    , Cmd.none
    )


gotFetchMealsResponse : Page.Model -> Result Error (List Meal) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealsResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\meals ->
                model
                    |> Page.lenses.meals.set
                        (meals
                            |> List.map (\meal -> ( meal.id, meal |> Editing.asView ))
                            |> Dict.fromList
                        )
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meals).set True
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
                |> Compose.lensWithLens Pagination.lenses.meals
        }
        model
        string
    , Cmd.none
    )


mapMealStateById : MealId -> (Page.MealState -> Page.MealState) -> Page.Model -> Page.Model
mapMealStateById mealId =
    Page.lenses.meals
        |> LensUtil.updateById mealId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
