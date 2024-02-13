module Api.Types.ComplexFoodCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias ComplexFoodCreation =
    { recipeId : Uuid, amountGrams : Float, amountMilliLitres : Maybe Float }


decoderComplexFoodCreation : Decode.Decoder ComplexFoodCreation
decoderComplexFoodCreation =
    Decode.succeed ComplexFoodCreation |> required "recipeId" Uuid.decoder |> required "amountGrams" Decode.float |> optional "amountMilliLitres" (Decode.maybe Decode.float) Nothing


encoderComplexFoodCreation : ComplexFoodCreation -> Encode.Value
encoderComplexFoodCreation obj =
    Encode.object [ ( "recipeId", Uuid.encode obj.recipeId ), ( "amountGrams", Encode.float obj.amountGrams ), ( "amountMilliLitres", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.amountMilliLitres) ) ]
