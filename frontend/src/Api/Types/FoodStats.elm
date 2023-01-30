module Api.Types.FoodStats exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.FoodNutrientInformation exposing (..)

type alias FoodStats = { nutrients: (List FoodNutrientInformation), weightInGrams: Float }


decoderFoodStats : Decode.Decoder FoodStats
decoderFoodStats = Decode.succeed FoodStats |> required "nutrients" (Decode.list (Decode.lazy (\_ -> decoderFoodNutrientInformation))) |> required "weightInGrams" Decode.float


encoderFoodStats : FoodStats -> Encode.Value
encoderFoodStats obj = Encode.object [ ("nutrients", Encode.list encoderFoodNutrientInformation obj.nutrients), ("weightInGrams", Encode.float obj.weightInGrams) ]