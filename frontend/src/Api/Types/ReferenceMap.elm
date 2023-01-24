module Api.Types.ReferenceMap exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

type alias ReferenceMap = { id: Uuid, name: String }


decoderReferenceMap : Decode.Decoder ReferenceMap
decoderReferenceMap = Decode.succeed ReferenceMap |> required "id" Uuid.decoder |> required "name" Decode.string


encoderReferenceMap : ReferenceMap -> Encode.Value
encoderReferenceMap obj = Encode.object [ ("id", Uuid.encode obj.id), ("name", Encode.string obj.name) ]