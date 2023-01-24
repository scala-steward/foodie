module Api.Types.Ingredient exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.AmountUnit exposing (..)
import Uuid exposing (Uuid)

type alias Ingredient = { id: Uuid, foodId: Int, amountUnit: AmountUnit }


decoderIngredient : Decode.Decoder Ingredient
decoderIngredient = Decode.succeed Ingredient |> required "id" Uuid.decoder |> required "foodId" Decode.int |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredient : Ingredient -> Encode.Value
encoderIngredient obj = Encode.object [ ("id", Uuid.encode obj.id), ("foodId", Encode.int obj.foodId), ("amountUnit", encoderAmountUnit obj.amountUnit) ]