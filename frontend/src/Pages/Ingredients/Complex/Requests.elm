module Pages.Ingredients.Complex.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexIngredient exposing (ComplexIngredient, decoderComplexIngredient, encoderComplexIngredient)
import Http
import Json.Decode as Decode
import Pages.Ingredients.Complex.Page as Page
import Pages.Util.Choice.Page as ChoiceGroup
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil exposing (Error)


fetchComplexIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
fetchComplexIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson ChoiceGroup.GotFetchElementsResponse (Decode.list decoderComplexIngredient)
        }


fetchComplexFoods : AuthorizedAccess -> Cmd Page.LogicMsg
fetchComplexFoods =
    Pages.Util.Requests.fetchComplexFoodsWith ChoiceGroup.GotFetchChoicesResponse


createComplexIngredient :
    AuthorizedAccess
    -> RecipeId
    -> ComplexIngredient
    -> Cmd Page.LogicMsg
createComplexIngredient authorizedAccess recipeId complexIngredient =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.complexIngredients.create recipeId)
        { body = encoderComplexIngredient complexIngredient |> Http.jsonBody
        , expect = HttpUtil.expectJson ChoiceGroup.GotCreateResponse decoderComplexIngredient
        }


saveComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredient -> Cmd Page.LogicMsg
saveComplexIngredient flags recipeId complexIngredient =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.update recipeId)
        { body = encoderComplexIngredient complexIngredient |> Http.jsonBody
        , expect = HttpUtil.expectJson ChoiceGroup.GotSaveEditResponse decoderComplexIngredient
        }


deleteComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredientId -> Cmd Page.LogicMsg
deleteComplexIngredient flags recipeId complexIngredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.delete recipeId complexIngredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (ChoiceGroup.GotDeleteResponse complexIngredientId)
        }
