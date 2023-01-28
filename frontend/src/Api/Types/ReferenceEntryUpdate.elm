module Api.Types.ReferenceEntryUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Uuid exposing (Uuid)

type alias ReferenceEntryUpdate = { referenceMapId: Uuid, nutrientCode: Int, amount: Float }


decoderReferenceEntryUpdate : Decode.Decoder ReferenceEntryUpdate
decoderReferenceEntryUpdate = Decode.succeed ReferenceEntryUpdate |> required "referenceMapId" Uuid.decoder |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceEntryUpdate : ReferenceEntryUpdate -> Encode.Value
encoderReferenceEntryUpdate obj = Encode.object [ ("referenceMapId", Uuid.encode obj.referenceMapId), ("nutrientCode", Encode.int obj.nutrientCode), ("amount", Encode.float obj.amount) ]