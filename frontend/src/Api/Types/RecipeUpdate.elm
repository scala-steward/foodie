module Api.Types.RecipeUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias RecipeUpdate =
    { name : String, description : Maybe String, numberOfServings : Float, servingSize : Maybe String }


decoderRecipeUpdate : Decode.Decoder RecipeUpdate
decoderRecipeUpdate =
    Decode.succeed RecipeUpdate |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing |> required "numberOfServings" Decode.float |> optional "servingSize" (Decode.maybe Decode.string) Nothing


encoderRecipeUpdate : RecipeUpdate -> Encode.Value
encoderRecipeUpdate obj =
    Encode.object [ ( "name", Encode.string obj.name ), ( "description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description) ), ( "numberOfServings", Encode.float obj.numberOfServings ), ( "servingSize", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.servingSize) ) ]
