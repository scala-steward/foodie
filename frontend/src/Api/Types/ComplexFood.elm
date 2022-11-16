module Api.Types.ComplexFood exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

import Api.Types.ComplexFoodUnit exposing (..)

type alias ComplexFood = { recipeId: UUID, amount: Float, name: String, description: (Maybe String), unit: ComplexFoodUnit }


decoderComplexFood : Decode.Decoder ComplexFood
decoderComplexFood = Decode.succeed ComplexFood |> required "recipeId" decoderUUID |> required "amount" Decode.float |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing |> required "unit" decoderComplexFoodUnit


encoderComplexFood : ComplexFood -> Encode.Value
encoderComplexFood obj = Encode.object [ ("recipeId", encoderUUID obj.recipeId), ("amount", Encode.float obj.amount), ("name", Encode.string obj.name), ("description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description)), ("unit", encoderComplexFoodUnit obj.unit) ]