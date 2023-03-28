module Pages.Ingredients.Requests exposing
    ( createComplexIngredient
    , createIngredient
    , deleteComplexIngredient
    , deleteIngredient
    , fetchComplexFoods
    , fetchComplexIngredients
    , fetchFoods
    , fetchIngredients
    , saveComplexIngredient
    , saveIngredient
    )

import Addresses.Backend
import Api.Auxiliary exposing (ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexIngredient exposing (ComplexIngredient, decoderComplexIngredient, encoderComplexIngredient)
import Api.Types.Ingredient exposing (Ingredient, decoderIngredient)
import Api.Types.IngredientCreation exposing (IngredientCreation, encoderIngredientCreation)
import Api.Types.IngredientUpdate exposing (IngredientUpdate, encoderIngredientUpdate)
import Http
import Json.Decode as Decode
import Pages.Ingredients.FoodGroup as FoodGroup
import Pages.Ingredients.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil exposing (Error)



-- todo: Separate into two files


fetchIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.IngredientsGroupMsg
fetchIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson FoodGroup.GotFetchResponse (Decode.list decoderIngredient)
        }


fetchComplexIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.ComplexIngredientsGroupMsg
fetchComplexIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson FoodGroup.GotFetchResponse (Decode.list decoderComplexIngredient)
        }


fetchFoods : AuthorizedAccess -> Cmd Page.IngredientsGroupMsg
fetchFoods =
    Pages.Util.Requests.fetchFoodsWith FoodGroup.GotFetchFoodsResponse


fetchComplexFoods : AuthorizedAccess -> Cmd Page.ComplexIngredientsGroupMsg
fetchComplexFoods =
    Pages.Util.Requests.fetchComplexFoodsWith FoodGroup.GotFetchFoodsResponse


createIngredient :
    AuthorizedAccess
    -> IngredientCreation
    -> Cmd Page.IngredientsGroupMsg
createIngredient authorizedAccess ingredientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.ingredients.create
        { body = encoderIngredientCreation ingredientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson FoodGroup.GotCreateResponse decoderIngredient
        }


createComplexIngredient :
    AuthorizedAccess
    -> RecipeId
    -> ComplexIngredient
    -> Cmd Page.ComplexIngredientsGroupMsg
createComplexIngredient authorizedAccess recipeId complexIngredient =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.complexIngredients.create recipeId)
        { body = encoderComplexIngredient complexIngredient |> Http.jsonBody
        , expect = HttpUtil.expectJson FoodGroup.GotCreateResponse decoderComplexIngredient
        }


saveIngredient : AuthorizedAccess -> IngredientUpdate -> Cmd Page.IngredientsGroupMsg
saveIngredient flags ingredientUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.ingredients.update
        { body = encoderIngredientUpdate ingredientUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson FoodGroup.GotSaveEditResponse decoderIngredient
        }


saveComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredient -> Cmd Page.ComplexIngredientsGroupMsg
saveComplexIngredient flags recipeId complexIngredient =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.update recipeId)
        { body = encoderComplexIngredient complexIngredient |> Http.jsonBody
        , expect = HttpUtil.expectJson FoodGroup.GotSaveEditResponse decoderComplexIngredient
        }


deleteIngredient : AuthorizedAccess -> IngredientId -> Cmd Page.IngredientsGroupMsg
deleteIngredient flags ingredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.delete ingredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (FoodGroup.GotDeleteResponse ingredientId)
        }


deleteComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredientId -> Cmd Page.ComplexIngredientsGroupMsg
deleteComplexIngredient flags recipeId complexIngredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.delete recipeId complexIngredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (FoodGroup.GotDeleteResponse complexIngredientId)
        }
