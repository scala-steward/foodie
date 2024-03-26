module Pages.Meals.Editor.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealId, ProfileId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (MealCreation, encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate)
import Http
import Pages.Meals.Editor.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchMeals : AuthorizedAccess -> ProfileId -> Cmd Page.LogicMsg
fetchMeals =
    Pages.Util.Requests.fetchMealsWith (Pages.Util.ParentEditor.Page.GotFetchResponse >> Page.ParentEditorMsg)


createMeal : AuthorizedAccess -> ProfileId -> MealCreation -> Cmd Page.ParentLogicMsg
createMeal authorizedAccess profileId mealCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.create profileId)
        { body = encoderMealCreation mealCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.ParentEditor.Page.GotCreateResponse decoderMeal
        }


saveMeal :
    AuthorizedAccess
    -> ProfileId
    -> MealId
    -> MealUpdate
    -> Cmd Page.ParentLogicMsg
saveMeal =
    Pages.Util.Requests.saveMealWith Pages.Util.ParentEditor.Page.GotSaveEditResponse


deleteMeal :
    AuthorizedAccess
    -> ProfileId
    -> MealId
    -> Cmd Page.ParentLogicMsg
deleteMeal authorizedAccess profileId mealId =
    Pages.Util.Requests.deleteMealWith
        (Pages.Util.ParentEditor.Page.GotDeleteResponse mealId)
        authorizedAccess
        profileId
        mealId
