module Api.Types.IngredientUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.AmountUnit exposing (..)
import Uuid exposing (Uuid)

type alias IngredientUpdate = { ingredientId: Uuid, amountUnit: AmountUnit }


decoderIngredientUpdate : Decode.Decoder IngredientUpdate
decoderIngredientUpdate = Decode.succeed IngredientUpdate |> required "ingredientId" Uuid.decoder |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientUpdate : IngredientUpdate -> Encode.Value
encoderIngredientUpdate obj = Encode.object [ ("ingredientId", Uuid.encode obj.ingredientId), ("amountUnit", encoderAmountUnit obj.amountUnit) ]