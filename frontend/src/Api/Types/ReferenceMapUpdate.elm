module Api.Types.ReferenceMapUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias ReferenceMapUpdate =
    { id : Uuid, name : String }


decoderReferenceMapUpdate : Decode.Decoder ReferenceMapUpdate
decoderReferenceMapUpdate =
    Decode.succeed ReferenceMapUpdate |> required "id" Uuid.decoder |> required "name" Decode.string


encoderReferenceMapUpdate : ReferenceMapUpdate -> Encode.Value
encoderReferenceMapUpdate obj =
    Encode.object [ ( "id", Uuid.encode obj.id ), ( "name", Encode.string obj.name ) ]
