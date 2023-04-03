module Api.Types.MealEntryCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias MealEntryCreation =
    { mealId : Uuid, recipeId : Uuid, numberOfServings : Float }


decoderMealEntryCreation : Decode.Decoder MealEntryCreation
decoderMealEntryCreation =
    Decode.succeed MealEntryCreation |> required "mealId" Uuid.decoder |> required "recipeId" Uuid.decoder |> required "numberOfServings" Decode.float


encoderMealEntryCreation : MealEntryCreation -> Encode.Value
encoderMealEntryCreation obj =
    Encode.object [ ( "mealId", Uuid.encode obj.mealId ), ( "recipeId", Uuid.encode obj.recipeId ), ( "numberOfServings", Encode.float obj.numberOfServings ) ]
