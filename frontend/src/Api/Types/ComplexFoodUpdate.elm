module Api.Types.ComplexFoodUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ComplexFoodUpdate =
    { amountGrams : Float, amountMilliLitres : Maybe Float }


decoderComplexFoodUpdate : Decode.Decoder ComplexFoodUpdate
decoderComplexFoodUpdate =
    Decode.succeed ComplexFoodUpdate |> required "amountGrams" Decode.float |> optional "amountMilliLitres" (Decode.maybe Decode.float) Nothing


encoderComplexFoodUpdate : ComplexFoodUpdate -> Encode.Value
encoderComplexFoodUpdate obj =
    Encode.object [ ( "amountGrams", Encode.float obj.amountGrams ), ( "amountMilliLitres", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.amountMilliLitres) ) ]
