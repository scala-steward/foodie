module Api.Types.TotalOnlyAmount exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias TotalOnlyAmount = { values: (Maybe Float), numberOfIngredients: Int, numberOfDefinedValues: Int }


decoderTotalOnlyAmount : Decode.Decoder TotalOnlyAmount
decoderTotalOnlyAmount = Decode.succeed TotalOnlyAmount |> optional "values" (Decode.maybe Decode.float) Nothing |> required "numberOfIngredients" Decode.int |> required "numberOfDefinedValues" Decode.int


encoderTotalOnlyAmount : TotalOnlyAmount -> Encode.Value
encoderTotalOnlyAmount obj = Encode.object [ ("values", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.values)), ("numberOfIngredients", Encode.int obj.numberOfIngredients), ("numberOfDefinedValues", Encode.int obj.numberOfDefinedValues) ]