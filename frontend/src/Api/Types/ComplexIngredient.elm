module Api.Types.ComplexIngredient exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

type alias ComplexIngredient = { complexFoodId: Uuid, factor: Float }


decoderComplexIngredient : Decode.Decoder ComplexIngredient
decoderComplexIngredient = Decode.succeed ComplexIngredient |> required "complexFoodId" Uuid.decoder |> required "factor" Decode.float


encoderComplexIngredient : ComplexIngredient -> Encode.Value
encoderComplexIngredient obj = Encode.object [ ("complexFoodId", Uuid.encode obj.complexFoodId), ("factor", Encode.float obj.factor) ]