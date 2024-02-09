module Pages.Ingredients.Complex.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexIngredient exposing (ComplexIngredient, decoderComplexIngredient)
import Api.Types.ComplexIngredientCreation exposing (ComplexIngredientCreation, encoderComplexIngredientCreation)
import Api.Types.ComplexIngredientUpdate exposing (ComplexIngredientUpdate, encoderComplexIngredientUpdate)
import Http
import Json.Decode as Decode
import Pages.Ingredients.Complex.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil exposing (Error)


fetchComplexIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
fetchComplexIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotFetchElementsResponse (Decode.list decoderComplexIngredient)
        }


fetchComplexFoods : AuthorizedAccess -> Cmd Page.LogicMsg
fetchComplexFoods =
    Pages.Util.Requests.fetchComplexFoodsWith Pages.Util.Choice.Page.GotFetchChoicesResponse


createComplexIngredient :
    AuthorizedAccess
    -> RecipeId
    -> ComplexFoodId
    -> ComplexIngredientCreation
    -> Cmd Page.LogicMsg
createComplexIngredient authorizedAccess recipeId complexFoodId complexIngredientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.complexIngredients.create recipeId complexFoodId)
        { body = encoderComplexIngredientCreation complexIngredientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotCreateResponse decoderComplexIngredient
        }


saveComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexFoodId -> ComplexIngredientUpdate -> Cmd Page.LogicMsg
saveComplexIngredient flags recipeId complexFoodId complexIngredientUpdate =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.update recipeId complexFoodId)
        { body = encoderComplexIngredientUpdate complexIngredientUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotSaveEditResponse decoderComplexIngredient
        }


deleteComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredientId -> Cmd Page.LogicMsg
deleteComplexIngredient flags recipeId complexIngredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.delete recipeId complexIngredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Pages.Util.Choice.Page.GotDeleteResponse complexIngredientId)
        }
