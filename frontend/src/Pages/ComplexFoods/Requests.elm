module Pages.ComplexFoods.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ComplexFoodId)
import Api.Types.ComplexFood exposing (ComplexFood, decoderComplexFood, encoderComplexFood)
import Http
import Json.Decode as Decode
import Pages.ComplexFoods.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchRecipes : AuthorizedAccess -> Cmd Page.Msg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Page.GotFetchRecipesResponse


fetchComplexFoods : AuthorizedAccess -> Cmd Page.Msg
fetchComplexFoods authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchComplexFoodsResponse (Decode.list decoderComplexFood)
        }


createComplexFood : AuthorizedAccess -> ComplexFood -> Cmd Page.Msg
createComplexFood authorizedAccess complexFood =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.create
        { body = encoderComplexFood complexFood |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateComplexFoodResponse decoderComplexFood
        }


updateComplexFood : AuthorizedAccess -> ComplexFood -> Cmd Page.Msg
updateComplexFood authorizedAccess complexFood =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.update
        { body = encoderComplexFood complexFood |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveComplexFoodResponse decoderComplexFood
        }


deleteComplexFood : AuthorizedAccess -> ComplexFoodId -> Cmd Page.Msg
deleteComplexFood authorizedAccess complexFoodId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.complexFoods.delete complexFoodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteComplexFoodResponse complexFoodId)
        }
