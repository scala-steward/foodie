module Api.Types.MealEntryUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias MealEntryUpdate =
    { numberOfServings : Float }


decoderMealEntryUpdate : Decode.Decoder MealEntryUpdate
decoderMealEntryUpdate =
    Decode.succeed MealEntryUpdate |> required "numberOfServings" Decode.float


encoderMealEntryUpdate : MealEntryUpdate -> Encode.Value
encoderMealEntryUpdate obj =
    Encode.object [ ( "numberOfServings", Encode.float obj.numberOfServings ) ]
