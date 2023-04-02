module Pages.Meals.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (MealCreation, encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate)
import Http
import Pages.Meals.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchMeals : AuthorizedAccess -> Cmd Page.LogicMsg
fetchMeals =
    Pages.Util.Requests.fetchMealsWith Pages.Util.ParentEditor.Page.GotFetchResponse


createMeal : AuthorizedAccess -> MealCreation -> Cmd Page.LogicMsg
createMeal authorizedAccess mealCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.create
        { body = encoderMealCreation mealCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.ParentEditor.Page.GotCreateResponse decoderMeal
        }


saveMeal :
    AuthorizedAccess
    -> MealUpdate
    -> Cmd Page.LogicMsg
saveMeal authorizedAccess mealUpdate =
    Pages.Util.Requests.saveMealWith Pages.Util.ParentEditor.Page.GotSaveEditResponse
        { authorizedAccess = authorizedAccess
        , mealUpdate = mealUpdate
        }


deleteMeal :
    AuthorizedAccess
    -> MealId
    -> Cmd Page.LogicMsg
deleteMeal authorizedAccess mealId =
    Pages.Util.Requests.deleteMealWith (Pages.Util.ParentEditor.Page.GotDeleteResponse mealId)
        { authorizedAccess = authorizedAccess
        , mealId = mealId
        }
