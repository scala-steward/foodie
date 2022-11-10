module Api.Types.NutrientInformationBase exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.NutrientUnit exposing (..)

type alias NutrientInformationBase = { nutrientCode: Int, name: String, symbol: String, unit: NutrientUnit }


decoderNutrientInformationBase : Decode.Decoder NutrientInformationBase
decoderNutrientInformationBase = Decode.succeed NutrientInformationBase |> required "nutrientCode" Decode.int |> required "name" Decode.string |> required "symbol" Decode.string |> required "unit" decoderNutrientUnit


encoderNutrientInformationBase : NutrientInformationBase -> Encode.Value
encoderNutrientInformationBase obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("name", Encode.string obj.name), ("symbol", Encode.string obj.symbol), ("unit", encoderNutrientUnit obj.unit) ]