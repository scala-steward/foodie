module Api.Types.ComplexFoodIncoming exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias ComplexFoodIncoming =
    { recipeId : Uuid, amountGrams : Float, amountMilliLitres : Maybe Float }


decoderComplexFoodIncoming : Decode.Decoder ComplexFoodIncoming
decoderComplexFoodIncoming =
    Decode.succeed ComplexFoodIncoming |> required "recipeId" Uuid.decoder |> required "amountGrams" Decode.float |> optional "amountMilliLitres" (Decode.maybe Decode.float) Nothing


encoderComplexFoodIncoming : ComplexFoodIncoming -> Encode.Value
encoderComplexFoodIncoming obj =
    Encode.object [ ( "recipeId", Uuid.encode obj.recipeId ), ( "amountGrams", Encode.float obj.amountGrams ), ( "amountMilliLitres", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.amountMilliLitres) ) ]
