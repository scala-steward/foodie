module Api.Types.IngredientCreation exposing (..)

import Api.Types.AmountUnit exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias IngredientCreation =
    { recipeId : Uuid, foodId : Int, amountUnit : AmountUnit }


decoderIngredientCreation : Decode.Decoder IngredientCreation
decoderIngredientCreation =
    Decode.succeed IngredientCreation |> required "recipeId" Uuid.decoder |> required "foodId" Decode.int |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientCreation : IngredientCreation -> Encode.Value
encoderIngredientCreation obj =
    Encode.object [ ( "recipeId", Uuid.encode obj.recipeId ), ( "foodId", Encode.int obj.foodId ), ( "amountUnit", encoderAmountUnit obj.amountUnit ) ]
