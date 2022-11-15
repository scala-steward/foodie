module Pages.Util.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (MealId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood, decoderComplexFood)
import Api.Types.Food exposing (Food, decoderFood)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Http
import Json.Decode as Decode
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil exposing (Error)


fetchFoodsWith : (Result Error (List Food) -> msg) -> AuthorizedAccess -> Cmd msg
fetchFoodsWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.foods
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderFood)
        }

fetchComplexFoodsWith : (Result Error (List ComplexFood) -> msg) -> AuthorizedAccess -> Cmd msg
fetchComplexFoodsWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderComplexFood)
        }

fetchRecipesWith : (Result Error (List Recipe) -> msg) -> AuthorizedAccess -> Cmd msg
fetchRecipesWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderRecipe)
        }


fetchRecipeWith :
    (Result Error Recipe -> msg)
    -> { authorizedAccess : AuthorizedAccess, recipeId : RecipeId }
    -> Cmd msg
fetchRecipeWith mkMsg flags =
    HttpUtil.runPatternWithJwt
        flags.authorizedAccess
        (Addresses.Backend.recipes.single flags.recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg decoderRecipe
        }


fetchMealsWith :
    (Result Error (List Meal) -> msg)
    -> AuthorizedAccess
    -> Cmd msg
fetchMealsWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderMeal)
        }


fetchMealWith :
    (Result Error Meal -> msg)
    ->
        { authorizedAccess : AuthorizedAccess
        , mealId : MealId
        }
    -> Cmd msg
fetchMealWith mkMsg ps =
    HttpUtil.runPatternWithJwt
        ps.authorizedAccess
        (Addresses.Backend.meals.single ps.mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg decoderMeal
        }
