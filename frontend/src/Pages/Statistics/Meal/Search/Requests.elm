module Pages.Statistics.Meal.Search.Requests exposing (fetchMeals)

import Api.Auxiliary exposing (ProfileId)
import Pages.Statistics.Meal.Search.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests


fetchMeals : AuthorizedAccess -> ProfileId -> Cmd Page.LogicMsg
fetchMeals =
    Pages.Util.Requests.fetchMealsWith Page.GotFetchMealsResponse
