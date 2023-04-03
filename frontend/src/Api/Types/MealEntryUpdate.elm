module Api.Types.MealEntryUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias MealEntryUpdate =
    { mealEntryId : Uuid, recipeId : Uuid, numberOfServings : Float }


decoderMealEntryUpdate : Decode.Decoder MealEntryUpdate
decoderMealEntryUpdate =
    Decode.succeed MealEntryUpdate |> required "mealEntryId" Uuid.decoder |> required "recipeId" Uuid.decoder |> required "numberOfServings" Decode.float


encoderMealEntryUpdate : MealEntryUpdate -> Encode.Value
encoderMealEntryUpdate obj =
    Encode.object [ ( "mealEntryId", Uuid.encode obj.mealEntryId ), ( "recipeId", Uuid.encode obj.recipeId ), ( "numberOfServings", Encode.float obj.numberOfServings ) ]
