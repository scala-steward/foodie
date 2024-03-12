module Pages.Meals.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (ProfileId)
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
    ( { parentEditor = Pages.Util.ParentEditor.Page.initial flags.authorizedAccess
      , profileId = flags.profileId
      }
    , Requests.fetchMeals flags.authorizedAccess flags.profileId |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    let
        ( updatedParentEditor, parentEditorCmd ) =
            Tristate.updateWith (updateLogic model.profileId) msg model.parentEditor
    in
    ( { parentEditor = updatedParentEditor
      , profileId = model.profileId
      }
    , parentEditorCmd
    )


updateLogic : ProfileId -> Page.LogicMsg -> Tristate.Model Page.Main Page.Initial -> ( Tristate.Model Page.Main Page.Initial, Cmd Page.LogicMsg )
updateLogic profileId =
    Pages.Util.ParentEditor.Handler.updateLogic
        { idOfParent = .id
        , toUpdate = MealUpdateClientInput.from
        , navigateToAddress = \mealId -> Addresses.Frontend.mealEntryEditor.address ( profileId, mealId )
        , updateCreationTimestamp = DateUtil.fromPosix >> SimpleDateInput.from >> MealCreationClientInput.lenses.date.set
        , create = \authorizedAccess -> MealCreationClientInput.toCreation >> Maybe.Extra.unwrap Cmd.none (Requests.createMeal authorizedAccess profileId)
        , save = \authorizedAccess mealId -> MealUpdateClientInput.to >> Maybe.Extra.unwrap Cmd.none (Requests.saveMeal authorizedAccess profileId mealId)
        , delete = \authorizedAccess -> Requests.deleteMeal authorizedAccess profileId
        , duplicate = \authorizedAccess -> Pages.Util.Requests.duplicateMealWith Pages.Util.ParentEditor.Page.GotDuplicateResponse authorizedAccess profileId
        }
