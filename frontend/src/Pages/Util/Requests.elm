module Pages.Util.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (MealId, ProfileId, RecipeId, ReferenceMapId)
import Api.Types.ComplexFood exposing (ComplexFood, decoderComplexFood)
import Api.Types.Food exposing (Food, decoderFood)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealUpdate exposing (MealUpdate, encoderMealUpdate)
import Api.Types.Profile exposing (Profile, decoderProfile)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate, encoderRecipeUpdate)
import Api.Types.ReferenceMap exposing (ReferenceMap, decoderReferenceMap)
import Api.Types.ReferenceMapUpdate exposing (ReferenceMapUpdate, encoderReferenceMapUpdate)
import Api.Types.SimpleDate exposing (encoderSimpleDate)
import Http
import Json.Decode as Decode
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.DateUtil as DateUtil
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
    -> AuthorizedAccess
    -> RecipeId
    -> Cmd msg
fetchRecipeWith mkMsg authorizedAccess recipeId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.single recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg decoderRecipe
        }


fetchMealsWith :
    (Result Error (List Meal) -> msg)
    -> AuthorizedAccess
    -> ProfileId
    -> Cmd msg
fetchMealsWith mkMsg authorizedAccess profileId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.all profileId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderMeal)
        }


fetchMealWith :
    (Result Error Meal -> msg)
    -> AuthorizedAccess
    -> ProfileId
    -> MealId
    -> Cmd msg
fetchMealWith mkMsg authorizedAccess profileId mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.single profileId mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg decoderMeal
        }


saveMealWith :
    (Result Error Meal -> msg)
    -> AuthorizedAccess
    -> ProfileId
    -> MealId
    -> MealUpdate
    -> Cmd msg
saveMealWith mkMsg authorizedAccess profileId mealId mealUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.update profileId mealId)
        { body = encoderMealUpdate mealUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson mkMsg decoderMeal
        }


deleteMealWith :
    (Result Error () -> msg)
    -> AuthorizedAccess
    -> ProfileId
    -> MealId
    -> Cmd msg
deleteMealWith mkMsg authorizedAccess profileId mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.delete profileId mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever mkMsg
        }


duplicateMealWith :
    (Result Error Meal -> msg)
    -> AuthorizedAccess
    -> ProfileId
    -> MealId
    -> DateUtil.Timestamp
    -> Cmd msg
duplicateMealWith mkMsg authorizedAccess profileId mealId timestamp =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.duplicate profileId mealId)
        { body = timestamp |> DateUtil.fromPosix |> encoderSimpleDate |> Http.jsonBody
        , expect = HttpUtil.expectJson mkMsg decoderMeal
        }


saveRecipeWith :
    (Result Error Recipe -> msg)
    -> AuthorizedAccess
    -> RecipeId
    -> RecipeUpdate
    -> Cmd msg
saveRecipeWith mkMsg authorizedAccess recipeId recipeUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.update recipeId)
        { body = encoderRecipeUpdate recipeUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson mkMsg decoderRecipe
        }


deleteRecipeWith :
    (Result Error () -> msg)
    -> AuthorizedAccess
    -> RecipeId
    -> Cmd msg
deleteRecipeWith mkMsg authorizedAccess recipeId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.delete recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever mkMsg
        }


duplicateRecipeWith :
    (Result Error Recipe -> msg)
    -> AuthorizedAccess
    -> RecipeId
    -> DateUtil.Timestamp
    -> Cmd msg
duplicateRecipeWith mkMsg authorizedAccess recipeId timestamp =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.duplicate recipeId)
        { body = timestamp |> DateUtil.fromPosix |> encoderSimpleDate |> Http.jsonBody
        , expect = HttpUtil.expectJson mkMsg decoderRecipe
        }


rescaleRecipeWith :
    (Result Error Recipe -> msg)
    -> AuthorizedAccess
    -> RecipeId
    -> Cmd msg
rescaleRecipeWith mkMsg authorizedAccess recipeId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.rescale recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg decoderRecipe
        }


saveReferenceMapWith :
    (Result Error ReferenceMap -> msg)
    -> AuthorizedAccess
    -> ReferenceMapId
    -> ReferenceMapUpdate
    -> Cmd msg
saveReferenceMapWith mkMsg authorizedAccess referenceMapId referenceMapUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.update referenceMapId)
        { body = encoderReferenceMapUpdate referenceMapUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson mkMsg decoderReferenceMap
        }


deleteReferenceMapWith :
    (Result Error () -> msg)
    -> AuthorizedAccess
    -> ReferenceMapId
    -> Cmd msg
deleteReferenceMapWith mkMsg authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.delete referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever mkMsg
        }


duplicateReferenceMapWith :
    (Result Error ReferenceMap -> msg)
    -> AuthorizedAccess
    -> ReferenceMapId
    -> DateUtil.Timestamp
    -> Cmd msg
duplicateReferenceMapWith mkMsg authorizedAccess referenceMapId timestamp =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.duplicate referenceMapId)
        { body = timestamp |> DateUtil.fromPosix |> encoderSimpleDate |> Http.jsonBody
        , expect = HttpUtil.expectJson mkMsg decoderReferenceMap
        }


fetchProfileWith :
    (Result Error Profile -> msg)
    -> AuthorizedAccess
    -> ProfileId
    -> Cmd msg
fetchProfileWith mkMsg authorizedAccess profileId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.profiles.single profileId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg decoderProfile
        }


fetchProfilesWith :
    (Result Error (List Profile) -> msg)
    -> AuthorizedAccess
    -> Cmd msg
fetchProfilesWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.profiles.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderProfile)
        }
