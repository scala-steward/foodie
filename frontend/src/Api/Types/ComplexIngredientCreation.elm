module Api.Types.ComplexIngredientCreation exposing (..)

import Api.Types.ScalingMode exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias ComplexIngredientCreation =
    { complexFoodId : Uuid, factor : Float, scalingMode : ScalingMode }


decoderComplexIngredientCreation : Decode.Decoder ComplexIngredientCreation
decoderComplexIngredientCreation =
    Decode.succeed ComplexIngredientCreation |> required "complexFoodId" Uuid.decoder |> required "factor" Decode.float |> required "scalingMode" decoderScalingMode


encoderComplexIngredientCreation : ComplexIngredientCreation -> Encode.Value
encoderComplexIngredientCreation obj =
    Encode.object [ ( "complexFoodId", Uuid.encode obj.complexFoodId ), ( "factor", Encode.float obj.factor ), ( "scalingMode", encoderScalingMode obj.scalingMode ) ]
