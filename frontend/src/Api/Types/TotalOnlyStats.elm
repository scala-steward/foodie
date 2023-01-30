module Api.Types.TotalOnlyStats exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.TotalOnlyNutrientInformation exposing (..)

type alias TotalOnlyStats = { nutrients: (List TotalOnlyNutrientInformation), weightInGrams: Float }


decoderTotalOnlyStats : Decode.Decoder TotalOnlyStats
decoderTotalOnlyStats = Decode.succeed TotalOnlyStats |> required "nutrients" (Decode.list (Decode.lazy (\_ -> decoderTotalOnlyNutrientInformation))) |> required "weightInGrams" Decode.float


encoderTotalOnlyStats : TotalOnlyStats -> Encode.Value
encoderTotalOnlyStats obj = Encode.object [ ("nutrients", Encode.list encoderTotalOnlyNutrientInformation obj.nutrients), ("weightInGrams", Encode.float obj.weightInGrams) ]