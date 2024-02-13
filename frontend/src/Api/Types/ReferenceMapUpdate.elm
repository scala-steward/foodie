module Api.Types.ReferenceMapUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceMapUpdate =
    { name : String }


decoderReferenceMapUpdate : Decode.Decoder ReferenceMapUpdate
decoderReferenceMapUpdate =
    Decode.succeed ReferenceMapUpdate |> required "name" Decode.string


encoderReferenceMapUpdate : ReferenceMapUpdate -> Encode.Value
encoderReferenceMapUpdate obj =
    Encode.object [ ( "name", Encode.string obj.name ) ]
