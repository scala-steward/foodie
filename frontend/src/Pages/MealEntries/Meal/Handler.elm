module Pages.MealEntries.Meal.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (MealId, ProfileId)
import Pages.MealEntries.Meal.Page as Page
import Pages.Meals.Editor.MealUpdateClientInput as MealUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Handler
import Pages.Util.Parent.Page
import Pages.Util.Requests


initialFetch : AuthorizedAccess -> ProfileId -> MealId -> Cmd Page.LogicMsg
initialFetch =
    Pages.Util.Requests.fetchMealWith Pages.Util.Parent.Page.GotFetchResponse


updateLogic : ProfileId -> Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic profileId =
    Pages.Util.Parent.Handler.updateLogic
        { toUpdate = MealUpdateClientInput.from
        , idOf = .id
        , save =
            \authorizedAccess mealId ->
                MealUpdateClientInput.to
                    >> Maybe.map
                        (Pages.Util.Requests.saveMealWith
                            Pages.Util.Parent.Page.GotSaveEditResponse
                            authorizedAccess
                            profileId
                            mealId
                        )
        , delete = \authorizedAccess -> Pages.Util.Requests.deleteMealWith Pages.Util.Parent.Page.GotDeleteResponse authorizedAccess profileId
        , duplicate = \authorizedAccess -> Pages.Util.Requests.duplicateMealWith Pages.Util.Parent.Page.GotDuplicateResponse authorizedAccess profileId
        , navigateAfterDeletionAddress = \_ -> Addresses.Frontend.meals.address profileId
        , navigateAfterDuplicationAddress = \mealId -> Addresses.Frontend.mealEntryEditor.address ( profileId, mealId )
        }
