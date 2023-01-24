module Api.Types.User exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

type alias User = { id: Uuid, nickname: String, displayName: (Maybe String), email: String }


decoderUser : Decode.Decoder User
decoderUser = Decode.succeed User |> required "id" Uuid.decoder |> required "nickname" Decode.string |> optional "displayName" (Decode.maybe Decode.string) Nothing |> required "email" Decode.string


encoderUser : User -> Encode.Value
encoderUser obj = Encode.object [ ("id", Uuid.encode obj.id), ("nickname", Encode.string obj.nickname), ("displayName", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.displayName)), ("email", Encode.string obj.email) ]