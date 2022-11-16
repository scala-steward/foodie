module Api.Types.FoodNutrientInformation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.NutrientInformationBase exposing (..)

type alias FoodNutrientInformation = { base: NutrientInformationBase, amount: (Maybe Float) }


decoderFoodNutrientInformation : Decode.Decoder FoodNutrientInformation
decoderFoodNutrientInformation = Decode.succeed FoodNutrientInformation |> required "base" (Decode.lazy (\_ -> decoderNutrientInformationBase)) |> optional "amount" (Decode.maybe Decode.float) Nothing


encoderFoodNutrientInformation : FoodNutrientInformation -> Encode.Value
encoderFoodNutrientInformation obj = Encode.object [ ("base", encoderNutrientInformationBase obj.base), ("amount", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.amount)) ]