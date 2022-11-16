module Api.Types.TotalOnlyStats exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.TotalOnlyNutrientInformation exposing (..)

type alias TotalOnlyStats = { nutrients: (List TotalOnlyNutrientInformation) }


decoderTotalOnlyStats : Decode.Decoder TotalOnlyStats
decoderTotalOnlyStats = Decode.succeed TotalOnlyStats |> required "nutrients" (Decode.list (Decode.lazy (\_ -> decoderTotalOnlyNutrientInformation)))


encoderTotalOnlyStats : TotalOnlyStats -> Encode.Value
encoderTotalOnlyStats obj = Encode.object [ ("nutrients", Encode.list encoderTotalOnlyNutrientInformation obj.nutrients) ]