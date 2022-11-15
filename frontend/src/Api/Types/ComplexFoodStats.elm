module Api.Types.ComplexFoodStats exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.FoodNutrientInformation exposing (..)
import Api.Types.ComplexFoodUnit exposing (..)

type alias ComplexFoodStats = { nutrients: (List FoodNutrientInformation), complexFoodUnit: ComplexFoodUnit }


decoderComplexFoodStats : Decode.Decoder ComplexFoodStats
decoderComplexFoodStats = Decode.succeed ComplexFoodStats |> required "nutrients" (Decode.list (Decode.lazy (\_ -> decoderFoodNutrientInformation))) |> required "complexFoodUnit" decoderComplexFoodUnit


encoderComplexFoodStats : ComplexFoodStats -> Encode.Value
encoderComplexFoodStats obj = Encode.object [ ("nutrients", Encode.list encoderFoodNutrientInformation obj.nutrients), ("complexFoodUnit", encoderComplexFoodUnit obj.complexFoodUnit) ]