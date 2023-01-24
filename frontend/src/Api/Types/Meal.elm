module Api.Types.Meal exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.SimpleDate exposing (..)
import Uuid exposing (Uuid)

type alias Meal = { id: Uuid, date: SimpleDate, name: (Maybe String) }


decoderMeal : Decode.Decoder Meal
decoderMeal = Decode.succeed Meal |> required "id" Uuid.decoder |> required "date" (Decode.lazy (\_ -> decoderSimpleDate)) |> optional "name" (Decode.maybe Decode.string) Nothing


encoderMeal : Meal -> Encode.Value
encoderMeal obj = Encode.object [ ("id", Uuid.encode obj.id), ("date", encoderSimpleDate obj.date), ("name", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.name)) ]