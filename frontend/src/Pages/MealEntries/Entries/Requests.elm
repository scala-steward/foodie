module Pages.MealEntries.Entries.Requests exposing
    ( createMealEntry
    , deleteMealEntry
    , fetchMealEntries
    , fetchRecipes
    , saveMealEntry
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry, decoderMealEntry)
import Api.Types.MealEntryCreation exposing (MealEntryCreation, encoderMealEntryCreation)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate, encoderMealEntryUpdate)
import Http
import Json.Decode as Decode
import Pages.MealEntries.Entries.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchMealEntries : AuthorizedAccess -> MealId -> Cmd Page.LogicMsg
fetchMealEntries authorizedAccess mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.allOf mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotFetchElementsResponse (Decode.list decoderMealEntry)
        }


fetchRecipes : AuthorizedAccess -> Cmd Page.LogicMsg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Pages.Util.Choice.Page.GotFetchChoicesResponse


saveMealEntry : AuthorizedAccess -> MealEntryUpdate -> Cmd Page.LogicMsg
saveMealEntry authorizedAccess mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.entries.update
        { body = encoderMealEntryUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotSaveEditResponse decoderMealEntry
        }


deleteMealEntry : AuthorizedAccess -> MealEntryId -> Cmd Page.LogicMsg
deleteMealEntry authorizedAccess mealEntryId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.delete mealEntryId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Pages.Util.Choice.Page.GotDeleteResponse mealEntryId)
        }


createMealEntry : AuthorizedAccess -> MealEntryCreation -> Cmd Page.LogicMsg
createMealEntry authorizedAccess mealEntryCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.entries.create
        { body = encoderMealEntryCreation mealEntryCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotCreateResponse decoderMealEntry
        }
