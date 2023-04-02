module Api.Types.NutrientInformation exposing (..)

import Api.Types.Amounts exposing (..)
import Api.Types.NutrientInformationBase exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias NutrientInformation =
    { base : NutrientInformationBase, amounts : Amounts }


decoderNutrientInformation : Decode.Decoder NutrientInformation
decoderNutrientInformation =
    Decode.succeed NutrientInformation |> required "base" (Decode.lazy (\_ -> decoderNutrientInformationBase)) |> required "amounts" (Decode.lazy (\_ -> decoderAmounts))


encoderNutrientInformation : NutrientInformation -> Encode.Value
encoderNutrientInformation obj =
    Encode.object [ ( "base", encoderNutrientInformationBase obj.base ), ( "amounts", encoderAmounts obj.amounts ) ]
