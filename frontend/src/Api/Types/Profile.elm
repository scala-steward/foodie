module Api.Types.Profile exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias Profile =
    { id : Uuid, name : String }


decoderProfile : Decode.Decoder Profile
decoderProfile =
    Decode.succeed Profile |> required "id" Uuid.decoder |> required "name" Decode.string


encoderProfile : Profile -> Encode.Value
encoderProfile obj =
    Encode.object [ ( "id", Uuid.encode obj.id ), ( "name", Encode.string obj.name ) ]
