module Api.Types.LoginContent exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

type alias LoginContent = { userId: Uuid, sessionId: Uuid, nickname: String }


decoderLoginContent : Decode.Decoder LoginContent
decoderLoginContent = Decode.succeed LoginContent |> required "userId" Uuid.decoder |> required "sessionId" Uuid.decoder |> required "nickname" Decode.string


encoderLoginContent : LoginContent -> Encode.Value
encoderLoginContent obj = Encode.object [ ("userId", Uuid.encode obj.userId), ("sessionId", Uuid.encode obj.sessionId), ("nickname", Encode.string obj.nickname) ]