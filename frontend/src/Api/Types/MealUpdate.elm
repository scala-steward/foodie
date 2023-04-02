module Api.Types.MealUpdate exposing (..)

import Api.Types.SimpleDate exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias MealUpdate =
    { id : Uuid, date : SimpleDate, name : Maybe String }


decoderMealUpdate : Decode.Decoder MealUpdate
decoderMealUpdate =
    Decode.succeed MealUpdate |> required "id" Uuid.decoder |> required "date" (Decode.lazy (\_ -> decoderSimpleDate)) |> optional "name" (Decode.maybe Decode.string) Nothing


encoderMealUpdate : MealUpdate -> Encode.Value
encoderMealUpdate obj =
    Encode.object [ ( "id", Uuid.encode obj.id ), ( "date", encoderSimpleDate obj.date ), ( "name", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.name) ) ]
