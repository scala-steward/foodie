module Pages.Recipes.Requests exposing (createRecipe, deleteRecipe, fetchRecipes, saveRecipe)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeCreation exposing (RecipeCreation, encoderRecipeCreation)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Http
import Pages.Recipes.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchRecipes : AuthorizedAccess -> Cmd Page.LogicMsg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Pages.Util.ParentEditor.Page.GotFetchResponse


createRecipe : AuthorizedAccess -> RecipeCreation -> Cmd Page.LogicMsg
createRecipe authorizedAccess recipeCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.create
        { body = encoderRecipeCreation recipeCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.ParentEditor.Page.GotCreateResponse decoderRecipe
        }



-- Todo: Remove entirely in favour of the generalised function?


saveRecipe :
    AuthorizedAccess
    -> RecipeUpdate
    -> Cmd Page.LogicMsg
saveRecipe =
    Pages.Util.Requests.saveRecipeWith
        Pages.Util.ParentEditor.Page.GotSaveEditResponse


deleteRecipe :
    AuthorizedAccess
    -> RecipeId
    -> Cmd Page.LogicMsg
deleteRecipe authorizedAccess recipeId =
    Pages.Util.Requests.deleteRecipeWith (Pages.Util.ParentEditor.Page.GotDeleteResponse recipeId)
        authorizedAccess
        recipeId
