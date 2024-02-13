module Api.Types.IngredientUpdate exposing (..)

import Api.Types.AmountUnit exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias IngredientUpdate =
    { amountUnit : AmountUnit }


decoderIngredientUpdate : Decode.Decoder IngredientUpdate
decoderIngredientUpdate =
    Decode.succeed IngredientUpdate |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientUpdate : IngredientUpdate -> Encode.Value
encoderIngredientUpdate obj =
    Encode.object [ ( "amountUnit", encoderAmountUnit obj.amountUnit ) ]
