module Api.Types.MealUpdate exposing (..)

import Api.Types.SimpleDate exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias MealUpdate =
    { date : SimpleDate, name : Maybe String }


decoderMealUpdate : Decode.Decoder MealUpdate
decoderMealUpdate =
    Decode.succeed MealUpdate |> required "date" (Decode.lazy (\_ -> decoderSimpleDate)) |> optional "name" (Decode.maybe Decode.string) Nothing


encoderMealUpdate : MealUpdate -> Encode.Value
encoderMealUpdate obj =
    Encode.object [ ( "date", encoderSimpleDate obj.date ), ( "name", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.name) ) ]
