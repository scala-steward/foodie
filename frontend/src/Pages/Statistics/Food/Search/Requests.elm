module Pages.Statistics.Food.Search.Requests exposing (fetchFoods)

import Pages.Statistics.Food.Search.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests


fetchFoods : AuthorizedAccess -> Cmd Page.LogicMsg
fetchFoods =
    Pages.Util.Requests.fetchFoodsWith Page.GotFetchFoodsResponse
