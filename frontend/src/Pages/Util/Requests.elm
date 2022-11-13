module Pages.Util.Requests exposing (..)

import Addresses.Backend
import Api.Types.Food exposing (Food, decoderFood)
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


fetchRecipesWith : (Result Error (List Recipe) -> msg) -> AuthorizedAccess -> Cmd msg
fetchRecipesWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderRecipe)
        }
