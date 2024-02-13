module Api.Types.IngredientCreation exposing (..)

import Api.Types.AmountUnit exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias IngredientCreation =
    { foodId : Int, amountUnit : AmountUnit }


decoderIngredientCreation : Decode.Decoder IngredientCreation
decoderIngredientCreation =
    Decode.succeed IngredientCreation |> required "foodId" Decode.int |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientCreation : IngredientCreation -> Encode.Value
encoderIngredientCreation obj =
    Encode.object [ ( "foodId", Encode.int obj.foodId ), ( "amountUnit", encoderAmountUnit obj.amountUnit ) ]
