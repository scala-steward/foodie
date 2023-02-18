module Pages.Statistics.Recipe.Search.Requests exposing (fetchRecipes)

import Pages.Statistics.Recipe.Search.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests


fetchRecipes : AuthorizedAccess -> Cmd Page.LogicMsg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Page.GotFetchRecipesResponse
