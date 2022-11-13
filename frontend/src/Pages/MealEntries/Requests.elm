module Pages.MealEntries.Requests exposing
    ( addMealEntry
    , deleteMealEntry
    , fetchMeal
    , fetchMealEntries
    , fetchRecipes
    , saveMealEntry
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (decoderMeal)
import Api.Types.MealEntry exposing (MealEntry, decoderMealEntry)
import Api.Types.MealEntryCreation exposing (MealEntryCreation, encoderMealEntryCreation)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate, encoderMealEntryUpdate)
import Http
import Json.Decode as Decode
import Pages.MealEntries.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchMeal : AuthorizedAccess -> MealId -> Cmd Page.Msg
fetchMeal authorizedAccess mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.single mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchMealResponse decoderMeal
        }


fetchMealEntries : AuthorizedAccess -> MealId -> Cmd Page.Msg
fetchMealEntries authorizedAccess mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.allOf mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchMealEntriesResponse (Decode.list decoderMealEntry)
        }


fetchRecipes : AuthorizedAccess -> Cmd Page.Msg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Page.GotFetchRecipesResponse


saveMealEntry : AuthorizedAccess -> MealEntryUpdate -> Cmd Page.Msg
saveMealEntry authorizedAccess mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.entries.update
        { body = encoderMealEntryUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveMealEntryResponse decoderMealEntry
        }


deleteMealEntry : AuthorizedAccess -> MealEntryId -> Cmd Page.Msg
deleteMealEntry authorizedAccess mealEntryId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.delete mealEntryId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteMealEntryResponse mealEntryId)
        }


addMealEntry : AuthorizedAccess -> MealEntryCreation -> Cmd Page.Msg
addMealEntry authorizedAccess mealEntryCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.entries.create
        { body = encoderMealEntryCreation mealEntryCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotAddMealEntryResponse decoderMealEntry
        }
