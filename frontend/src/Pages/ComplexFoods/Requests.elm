module Pages.ComplexFoods.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ComplexFoodId)
import Api.Types.ComplexFood exposing (ComplexFood, decoderComplexFood)
import Api.Types.ComplexFoodIncoming exposing (ComplexFoodIncoming, encoderComplexFoodIncoming)
import Http
import Json.Decode as Decode
import Pages.ComplexFoods.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchRecipes : AuthorizedAccess -> Cmd Page.LogicMsg
fetchRecipes =
    Pages.Util.Requests.fetchRecipesWith Page.GotFetchRecipesResponse


fetchComplexFoods : AuthorizedAccess -> Cmd Page.LogicMsg
fetchComplexFoods authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchComplexFoodsResponse (Decode.list decoderComplexFood)
        }


createComplexFood : AuthorizedAccess -> ComplexFoodIncoming -> Cmd Page.LogicMsg
createComplexFood authorizedAccess complexFood =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.create
        { body = encoderComplexFoodIncoming complexFood |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateComplexFoodResponse decoderComplexFood
        }


updateComplexFood : AuthorizedAccess -> ComplexFoodIncoming -> Cmd Page.LogicMsg
updateComplexFood authorizedAccess complexFood =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.update
        { body = encoderComplexFoodIncoming complexFood |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveComplexFoodResponse decoderComplexFood
        }


deleteComplexFood : AuthorizedAccess -> ComplexFoodId -> Cmd Page.LogicMsg
deleteComplexFood authorizedAccess complexFoodId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.complexFoods.delete complexFoodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteComplexFoodResponse complexFoodId)
        }
