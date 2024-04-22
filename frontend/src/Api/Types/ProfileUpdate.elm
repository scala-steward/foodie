module Api.Types.ProfileUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ProfileUpdate =
    { name : String }


decoderProfileUpdate : Decode.Decoder ProfileUpdate
decoderProfileUpdate =
    Decode.succeed ProfileUpdate |> required "name" Decode.string


encoderProfileUpdate : ProfileUpdate -> Encode.Value
encoderProfileUpdate obj =
    Encode.object [ ( "name", Encode.string obj.name ) ]
