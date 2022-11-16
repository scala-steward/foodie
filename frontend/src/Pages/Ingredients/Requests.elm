module Pages.Ingredients.Requests exposing
    ( addComplexFood
    , addFood
    , deleteComplexIngredient
    , deleteIngredient
    , fetchComplexFoods
    , fetchComplexIngredients
    , fetchFoods
    , fetchIngredients
    , fetchRecipe
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
import Pages.Ingredients.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil exposing (Error)


fetchIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.Msg
fetchIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchIngredientsResponse (Decode.list decoderIngredient)
        }


fetchComplexIngredients : AuthorizedAccess -> RecipeId -> Cmd Page.Msg
fetchComplexIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchComplexIngredientsResponse (Decode.list decoderComplexIngredient)
        }


fetchRecipe : Page.Flags -> Cmd Page.Msg
fetchRecipe =
    Pages.Util.Requests.fetchRecipeWith Page.GotFetchRecipeResponse


fetchFoods : AuthorizedAccess -> Cmd Page.Msg
fetchFoods =
    Pages.Util.Requests.fetchFoodsWith Page.GotFetchFoodsResponse


fetchComplexFoods : AuthorizedAccess -> Cmd Page.Msg
fetchComplexFoods =
    Pages.Util.Requests.fetchComplexFoodsWith Page.GotFetchComplexFoodsResponse


addFood :
    AuthorizedAccess
    -> IngredientCreation
    -> Cmd Page.Msg
addFood authorizedAccess ingredientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.ingredients.create
        { body = encoderIngredientCreation ingredientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotAddFoodResponse decoderIngredient
        }


addComplexFood :
    AuthorizedAccess
    -> RecipeId
    -> ComplexIngredient
    -> Cmd Page.Msg
addComplexFood authorizedAccess recipeId complexIngredient =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.complexIngredients.create recipeId)
        { body = encoderComplexIngredient complexIngredient |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotAddComplexFoodResponse decoderComplexIngredient
        }


saveIngredient : AuthorizedAccess -> IngredientUpdate -> Cmd Page.Msg
saveIngredient flags ingredientUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.ingredients.update
        { body = encoderIngredientUpdate ingredientUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveIngredientResponse decoderIngredient
        }


saveComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredient -> Cmd Page.Msg
saveComplexIngredient flags recipeId complexIngredient =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.update recipeId)
        { body = encoderComplexIngredient complexIngredient |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveComplexIngredientResponse decoderComplexIngredient
        }


deleteIngredient : AuthorizedAccess -> IngredientId -> Cmd Page.Msg
deleteIngredient flags ingredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.delete ingredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteIngredientResponse ingredientId)
        }


deleteComplexIngredient : AuthorizedAccess -> RecipeId -> ComplexIngredientId -> Cmd Page.Msg
deleteComplexIngredient flags recipeId complexIngredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.complexIngredients.delete recipeId complexIngredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteComplexIngredientResponse complexIngredientId)
        }
