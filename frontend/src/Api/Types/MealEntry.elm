module Api.Types.MealEntry exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias MealEntry =
    { id : Uuid, recipeId : Uuid, numberOfServings : Float }


decoderMealEntry : Decode.Decoder MealEntry
decoderMealEntry =
    Decode.succeed MealEntry |> required "id" Uuid.decoder |> required "recipeId" Uuid.decoder |> required "numberOfServings" Decode.float


encoderMealEntry : MealEntry -> Encode.Value
encoderMealEntry obj =
    Encode.object [ ( "id", Uuid.encode obj.id ), ( "recipeId", Uuid.encode obj.recipeId ), ( "numberOfServings", Encode.float obj.numberOfServings ) ]
