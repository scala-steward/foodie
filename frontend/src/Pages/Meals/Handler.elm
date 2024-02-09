module Pages.Meals.Handler exposing (init, update)

import Addresses.Frontend
import Api.Types.Meal exposing (Meal)
import Maybe.Extra
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Requests as Requests
import Pages.Util.DateUtil as DateUtil
import Pages.Util.ParentEditor.Handler
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Pages.Util.SimpleDateInput as SimpleDateInput
import Pages.View.Tristate as Tristate


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Pages.Util.ParentEditor.Page.initial flags.authorizedAccess
    , Requests.fetchMeals flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.ParentEditor.Handler.updateLogic
        { idOfParent = .id
        , toUpdate = MealUpdateClientInput.from
        , navigateToAddress = Addresses.Frontend.mealEntryEditor.address
        , updateCreationTimestamp = DateUtil.fromPosix >> SimpleDateInput.from >> MealCreationClientInput.lenses.date.set
        , create = \authorizedAccess -> MealCreationClientInput.toCreation >> Maybe.Extra.unwrap Cmd.none (Requests.createMeal authorizedAccess)
        , save = \authorizedAccess _ -> MealUpdateClientInput.to >> Maybe.Extra.unwrap Cmd.none (Requests.saveMeal authorizedAccess)
        , delete = Requests.deleteMeal
        , duplicate = Pages.Util.Requests.duplicateMealWith Pages.Util.ParentEditor.Page.GotDuplicateResponse
        }
