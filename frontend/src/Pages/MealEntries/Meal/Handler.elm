module Pages.MealEntries.Meal.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (MealId)
import Pages.MealEntries.Meal.Page as Page
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Handler
import Pages.Util.Parent.Page
import Pages.Util.Requests


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.LogicMsg
initialFetch =
    Pages.Util.Requests.fetchMealWith Pages.Util.Parent.Page.GotFetchResponse


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
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
                            mealId
                        )
        , delete = Pages.Util.Requests.deleteMealWith Pages.Util.Parent.Page.GotDeleteResponse
        , duplicate = Pages.Util.Requests.duplicateMealWith Pages.Util.Parent.Page.GotDuplicateResponse
        , navigateAfterDeletionAddress = Addresses.Frontend.meals.address
        , navigateAfterDuplicationAddress = Addresses.Frontend.mealEntryEditor.address
        }
