module Pages.Statistics.ComplexFood.Search.Requests exposing (fetchComplexFoods)

import Pages.Statistics.ComplexFood.Search.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests


fetchComplexFoods : AuthorizedAccess -> Cmd Page.LogicMsg
fetchComplexFoods =
    Pages.Util.Requests.fetchComplexFoodsWith Page.GotFetchComplexFoodsResponse
