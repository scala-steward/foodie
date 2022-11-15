module Api.Types.ComplexFoodIncoming exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

import Api.Types.ComplexFoodUnit exposing (..)

type alias ComplexFoodIncoming = { recipeId: UUID, amount: Float, unit: ComplexFoodUnit }


decoderComplexFoodIncoming : Decode.Decoder ComplexFoodIncoming
decoderComplexFoodIncoming = Decode.succeed ComplexFoodIncoming |> required "recipeId" decoderUUID |> required "amount" Decode.float |> required "unit" decoderComplexFoodUnit


encoderComplexFoodIncoming : ComplexFoodIncoming -> Encode.Value
encoderComplexFoodIncoming obj = Encode.object [ ("recipeId", encoderUUID obj.recipeId), ("amount", Encode.float obj.amount), ("unit", encoderComplexFoodUnit obj.unit) ]