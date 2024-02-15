module Api.Types.ReferenceEntryUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceEntryUpdate =
    { amount : Float }


decoderReferenceEntryUpdate : Decode.Decoder ReferenceEntryUpdate
decoderReferenceEntryUpdate =
    Decode.succeed ReferenceEntryUpdate |> required "amount" Decode.float


encoderReferenceEntryUpdate : ReferenceEntryUpdate -> Encode.Value
encoderReferenceEntryUpdate obj =
    Encode.object [ ( "amount", Encode.float obj.amount ) ]
