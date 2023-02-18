module Pages.Meals.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (MealCreation, encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate)
import Http
import Pages.Meals.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchMeals : AuthorizedAccess -> Cmd Page.LogicMsg
fetchMeals =
    Pages.Util.Requests.fetchMealsWith Page.GotFetchMealsResponse


createMeal : AuthorizedAccess -> MealCreation -> Cmd Page.LogicMsg
createMeal authorizedAccess mealCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.create
        { body = encoderMealCreation mealCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateMealResponse decoderMeal
        }


saveMeal :
    { authorizedAccess : AuthorizedAccess
    , mealUpdate : MealUpdate
    }
    -> Cmd Page.LogicMsg
saveMeal =
    Pages.Util.Requests.saveMealWith Page.GotSaveMealResponse


deleteMeal :
    { authorizedAccess : AuthorizedAccess
    , mealId : MealId
    }
    -> Cmd Page.LogicMsg
deleteMeal ps =
    Pages.Util.Requests.deleteMealWith (Page.GotDeleteMealResponse ps.mealId) ps
