module Api.Types.ComplexFood exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias ComplexFood =
    { recipeId : Uuid, amountGrams : Float, amountMilliLitres : Maybe Float, name : String, description : Maybe String }


decoderComplexFood : Decode.Decoder ComplexFood
decoderComplexFood =
    Decode.succeed ComplexFood |> required "recipeId" Uuid.decoder |> required "amountGrams" Decode.float |> optional "amountMilliLitres" (Decode.maybe Decode.float) Nothing |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing


encoderComplexFood : ComplexFood -> Encode.Value
encoderComplexFood obj =
    Encode.object [ ( "recipeId", Uuid.encode obj.recipeId ), ( "amountGrams", Encode.float obj.amountGrams ), ( "amountMilliLitres", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.amountMilliLitres) ), ( "name", Encode.string obj.name ), ( "description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description) ) ]
