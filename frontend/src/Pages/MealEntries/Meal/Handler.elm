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
initialFetch authorizedAccess mealId =
    Pages.Util.Requests.fetchMealWith Pages.Util.Parent.Page.GotFetchResponse
        { authorizedAccess = authorizedAccess
        , mealId = mealId
        }


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Parent.Handler.updateLogic
        { toUpdate = MealUpdateClientInput.from
        , idOf = .id
        , save =
            \authorizedAccess update ->
                update
                    |> MealUpdateClientInput.to
                    |> Maybe.map
                        (\mealUpdate ->
                            Pages.Util.Requests.saveMealWith
                                Pages.Util.Parent.Page.GotSaveEditResponse
                                { authorizedAccess = authorizedAccess
                                , mealUpdate = mealUpdate
                                }
                        )
        , delete =
            \authorizedAccess mealId ->
                Pages.Util.Requests.deleteMealWith Pages.Util.Parent.Page.GotDeleteResponse
                    { authorizedAccess = authorizedAccess
                    , mealId = mealId
                    }
        , navigateAfterDeletionAddress = Addresses.Frontend.meals.address
        }
