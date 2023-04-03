module Api.Types.TotalOnlyNutrientInformation exposing (..)

import Api.Types.NutrientInformationBase exposing (..)
import Api.Types.TotalOnlyAmount exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias TotalOnlyNutrientInformation =
    { base : NutrientInformationBase, amount : TotalOnlyAmount }


decoderTotalOnlyNutrientInformation : Decode.Decoder TotalOnlyNutrientInformation
decoderTotalOnlyNutrientInformation =
    Decode.succeed TotalOnlyNutrientInformation |> required "base" (Decode.lazy (\_ -> decoderNutrientInformationBase)) |> required "amount" (Decode.lazy (\_ -> decoderTotalOnlyAmount))


encoderTotalOnlyNutrientInformation : TotalOnlyNutrientInformation -> Encode.Value
encoderTotalOnlyNutrientInformation obj =
    Encode.object [ ( "base", encoderNutrientInformationBase obj.base ), ( "amount", encoderTotalOnlyAmount obj.amount ) ]
