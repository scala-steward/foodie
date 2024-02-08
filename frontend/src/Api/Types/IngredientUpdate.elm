module Api.Types.IngredientUpdate exposing (..)

import Api.Types.AmountUnit exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias IngredientUpdate =
    { recipeId : Uuid, ingredientId : Uuid, amountUnit : AmountUnit }


decoderIngredientUpdate : Decode.Decoder IngredientUpdate
decoderIngredientUpdate =
    Decode.succeed IngredientUpdate |> required "recipeId" Uuid.decoder |> required "ingredientId" Uuid.decoder |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientUpdate : IngredientUpdate -> Encode.Value
encoderIngredientUpdate obj =
    Encode.object [ ( "recipeId", Uuid.encode obj.recipeId ), ( "ingredientId", Uuid.encode obj.ingredientId ), ( "amountUnit", encoderAmountUnit obj.amountUnit ) ]
