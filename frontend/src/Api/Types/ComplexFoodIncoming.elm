module Api.Types.ComplexFoodIncoming exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

import Api.Types.ComplexFoodUnit exposing (..)

type alias ComplexFoodIncoming = { recipeId: Uuid, amount: Float, unit: ComplexFoodUnit }


decoderComplexFoodIncoming : Decode.Decoder ComplexFoodIncoming
decoderComplexFoodIncoming = Decode.succeed ComplexFoodIncoming |> required "recipeId" Uuid.decoder |> required "amount" Decode.float |> required "unit" decoderComplexFoodUnit


encoderComplexFoodIncoming : ComplexFoodIncoming -> Encode.Value
encoderComplexFoodIncoming obj = Encode.object [ ("recipeId", Uuid.encode obj.recipeId), ("amount", Encode.float obj.amount), ("unit", encoderComplexFoodUnit obj.unit) ]