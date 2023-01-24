module Api.Types.RecoveryRequest exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

type alias RecoveryRequest = { userId: Uuid }


decoderRecoveryRequest : Decode.Decoder RecoveryRequest
decoderRecoveryRequest = Decode.succeed RecoveryRequest |> required "userId" Uuid.decoder


encoderRecoveryRequest : RecoveryRequest -> Encode.Value
encoderRecoveryRequest obj = Encode.object [ ("userId", Uuid.encode obj.userId) ]