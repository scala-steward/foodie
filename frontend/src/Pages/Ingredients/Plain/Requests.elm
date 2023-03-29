module Pages.Ingredients.Plain.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Ingredient exposing (Ingredient, decoderIngredient)
import Api.Types.IngredientCreation exposing (IngredientCreation, encoderIngredientCreation)
import Api.Types.IngredientUpdate exposing (IngredientUpdate, encoderIngredientUpdate)
import Http
import Json.Decode as Decode
import Pages.Ingredients.FoodGroup as FoodGroup
import Pages.Ingredients.Plain.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil exposing (Error)


fetchIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
fetchIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson FoodGroup.GotFetchResponse (Decode.list decoderIngredient)
        }


fetchFoods : AuthorizedAccess -> Cmd Page.LogicMsg
fetchFoods =
    Pages.Util.Requests.fetchFoodsWith FoodGroup.GotFetchFoodsResponse


createIngredient :
    AuthorizedAccess
    -> IngredientCreation
    -> Cmd Page.LogicMsg
createIngredient authorizedAccess ingredientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.ingredients.create
        { body = encoderIngredientCreation ingredientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson FoodGroup.GotCreateResponse decoderIngredient
        }


saveIngredient : AuthorizedAccess -> IngredientUpdate -> Cmd Page.LogicMsg
saveIngredient flags ingredientUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.ingredients.update
        { body = encoderIngredientUpdate ingredientUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson FoodGroup.GotSaveEditResponse decoderIngredient
        }


deleteIngredient : AuthorizedAccess -> IngredientId -> Cmd Page.LogicMsg
deleteIngredient flags ingredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.delete ingredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (FoodGroup.GotDeleteResponse ingredientId)
        }
