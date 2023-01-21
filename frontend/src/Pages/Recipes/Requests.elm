module Pages.Recipes.Requests exposing (createRecipe, deleteRecipe, fetchRecipes, saveRecipe)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeCreation exposing (RecipeCreation, encoderRecipeCreation)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Http
import Pages.Recipes.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchRecipes : AuthorizedAccess -> Cmd Page.Msg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Page.GotFetchRecipesResponse


createRecipe : AuthorizedAccess -> RecipeCreation -> Cmd Page.Msg
createRecipe authorizedAccess recipeCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.create
        { body = encoderRecipeCreation recipeCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateRecipeResponse decoderRecipe
        }



-- Todo: Remove entirely in favour of the generalised function?


saveRecipe :
    { authorizedAccess : AuthorizedAccess
    , recipeUpdate : RecipeUpdate
    }
    -> Cmd Page.Msg
saveRecipe =
    Pages.Util.Requests.saveRecipeWith
        Page.GotSaveRecipeResponse


deleteRecipe :
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
    -> Cmd Page.Msg
deleteRecipe ps =
    Pages.Util.Requests.deleteRecipeWith (Page.GotDeleteRecipeResponse ps.recipeId) ps
