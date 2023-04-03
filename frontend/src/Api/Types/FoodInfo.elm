module Api.Types.FoodInfo exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias FoodInfo =
    { id : Int, name : String }


decoderFoodInfo : Decode.Decoder FoodInfo
decoderFoodInfo =
    Decode.succeed FoodInfo |> required "id" Decode.int |> required "name" Decode.string


encoderFoodInfo : FoodInfo -> Encode.Value
encoderFoodInfo obj =
    Encode.object [ ( "id", Encode.int obj.id ), ( "name", Encode.string obj.name ) ]
