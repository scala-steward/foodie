module Api.Types.ComplexIngredientUpdate exposing (..)

import Api.Types.ScalingMode exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ComplexIngredientUpdate =
    { factor : Float, scalingMode : ScalingMode }


decoderComplexIngredientUpdate : Decode.Decoder ComplexIngredientUpdate
decoderComplexIngredientUpdate =
    Decode.succeed ComplexIngredientUpdate |> required "factor" Decode.float |> required "scalingMode" decoderScalingMode


encoderComplexIngredientUpdate : ComplexIngredientUpdate -> Encode.Value
encoderComplexIngredientUpdate obj =
    Encode.object [ ( "factor", Encode.float obj.factor ), ( "scalingMode", encoderScalingMode obj.scalingMode ) ]
