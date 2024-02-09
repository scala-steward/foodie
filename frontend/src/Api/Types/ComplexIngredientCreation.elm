module Api.Types.ComplexIngredientCreation exposing (..)

import Api.Types.ScalingMode exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ComplexIngredientCreation =
    { factor : Float, scalingMode : ScalingMode }


decoderComplexIngredientCreation : Decode.Decoder ComplexIngredientCreation
decoderComplexIngredientCreation =
    Decode.succeed ComplexIngredientCreation |> required "factor" Decode.float |> required "scalingMode" decoderScalingMode


encoderComplexIngredientCreation : ComplexIngredientCreation -> Encode.Value
encoderComplexIngredientCreation obj =
    Encode.object [ ( "factor", Encode.float obj.factor ), ( "scalingMode", encoderScalingMode obj.scalingMode ) ]
