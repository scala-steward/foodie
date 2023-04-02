module Pages.Ingredients.Recipe.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Pages.Ingredients.Recipe.Page as Page
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Handler
import Pages.Util.Parent.Page
import Pages.Util.Requests


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Pages.Util.Requests.fetchRecipeWith Pages.Util.Parent.Page.GotFetchResponse
        { authorizedAccess = authorizedAccess
        , recipeId = recipeId
        }


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Parent.Handler.updateLogic
        { toUpdate = RecipeUpdateClientInput.from
        , idOf = .id
        , save =
            \authorizedAccess update ->
                update
                    |> RecipeUpdateClientInput.to
                    |> (\recipeUpdate ->
                            Pages.Util.Requests.saveRecipeWith
                                Pages.Util.Parent.Page.GotSaveEditResponse
                                { authorizedAccess = authorizedAccess
                                , recipeUpdate = recipeUpdate
                                }
                       )
                    |> Just
        , delete =
            \authorizedAccess recipeId ->
                Pages.Util.Requests.deleteRecipeWith Pages.Util.Parent.Page.GotDeleteResponse
                    { authorizedAccess = authorizedAccess
                    , recipeId = recipeId
                    }
        , navigateAfterDeletionAddress = Addresses.Frontend.recipes.address
        }
