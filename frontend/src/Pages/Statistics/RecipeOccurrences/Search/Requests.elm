module Pages.Statistics.RecipeOccurrences.Search.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ProfileId)
import Api.Types.RecipeOccurrence exposing (decoderRecipeOccurrence)
import Http
import Json.Decode as Decode
import Pages.Statistics.RecipeOccurrences.Search.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchRecipeOccurrences : AuthorizedAccess -> ProfileId -> Cmd Page.LogicMsg
fetchRecipeOccurrences authorizedAccess profileId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.stats.recipeOccurrences profileId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchRecipeOccurrencesResponse (Decode.list decoderRecipeOccurrence)
        }
