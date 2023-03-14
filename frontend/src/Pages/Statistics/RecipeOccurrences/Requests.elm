module Pages.Statistics.RecipeOccurrences.Requests exposing (..)

import Addresses.Backend
import Api.Types.RecipeOccurrence exposing (decoderRecipeOccurrence)
import Http
import Json.Decode as Decode
import Pages.Statistics.RecipeOccurrences.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchRecipeOccurrences : AuthorizedAccess -> Cmd Page.LogicMsg
fetchRecipeOccurrences authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.recipeOccurrences
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchRecipeOccurrencesResponse (Decode.list decoderRecipeOccurrence)
        }
