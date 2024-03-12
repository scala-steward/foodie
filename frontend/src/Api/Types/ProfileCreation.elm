module Api.Types.ProfileCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ProfileCreation =
    { name : String }


decoderProfileCreation : Decode.Decoder ProfileCreation
decoderProfileCreation =
    Decode.succeed ProfileCreation |> required "name" Decode.string


encoderProfileCreation : ProfileCreation -> Encode.Value
encoderProfileCreation obj =
    Encode.object [ ( "name", Encode.string obj.name ) ]
