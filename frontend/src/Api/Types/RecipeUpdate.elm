module Api.Types.RecipeUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias RecipeUpdate =
    { id : Uuid, name : String, description : Maybe String, numberOfServings : Float, servingSize : Maybe String }


decoderRecipeUpdate : Decode.Decoder RecipeUpdate
decoderRecipeUpdate =
    Decode.succeed RecipeUpdate |> required "id" Uuid.decoder |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing |> required "numberOfServings" Decode.float |> optional "servingSize" (Decode.maybe Decode.string) Nothing


encoderRecipeUpdate : RecipeUpdate -> Encode.Value
encoderRecipeUpdate obj =
    Encode.object [ ( "id", Uuid.encode obj.id ), ( "name", Encode.string obj.name ), ( "description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description) ), ( "numberOfServings", Encode.float obj.numberOfServings ), ( "servingSize", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.servingSize) ) ]
