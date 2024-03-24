module Pages.MealEntries.Entries.Requests exposing
    ( createMealEntry
    , deleteMealEntry
    , fetchMealEntries
    , fetchRecipes
    , saveMealEntry
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealEntryId, MealId, ProfileId, RecipeId)
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


fetchMealEntries : AuthorizedAccess -> ProfileId -> MealId -> Cmd Page.LogicMsg
fetchMealEntries authorizedAccess profileId mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.allOf profileId mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotFetchElementsResponse (Decode.list decoderMealEntry)
        }
        |> Cmd.map Page.ChoiceMsg


fetchRecipes : AuthorizedAccess -> Cmd Page.LogicMsg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith (Pages.Util.Choice.Page.GotFetchChoicesResponse >> Page.ChoiceMsg)


saveMealEntry : AuthorizedAccess -> ProfileId -> MealId -> MealEntryId -> MealEntryUpdate -> Cmd Page.ChoiceLogicMsg
saveMealEntry authorizedAccess profileId mealId mealEntryId mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.update profileId mealId mealEntryId)
        { body = encoderMealEntryUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotSaveEditResponse decoderMealEntry
        }


deleteMealEntry : AuthorizedAccess -> ProfileId -> MealId -> MealEntryId -> Cmd Page.ChoiceLogicMsg
deleteMealEntry authorizedAccess profileId mealId mealEntryId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.delete profileId mealId mealEntryId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Pages.Util.Choice.Page.GotDeleteResponse mealEntryId)
        }


createMealEntry : AuthorizedAccess -> ProfileId -> MealId -> MealEntryCreation -> Cmd Page.ChoiceLogicMsg
createMealEntry authorizedAccess profileId mealId mealEntryCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.create profileId mealId)
        { body = encoderMealEntryCreation mealEntryCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotCreateResponse decoderMealEntry
        }
