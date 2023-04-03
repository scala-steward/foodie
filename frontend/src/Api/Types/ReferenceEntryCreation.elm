module Api.Types.ReferenceEntryCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Uuid exposing (Uuid)


type alias ReferenceEntryCreation =
    { referenceMapId : Uuid, nutrientCode : Int, amount : Float }


decoderReferenceEntryCreation : Decode.Decoder ReferenceEntryCreation
decoderReferenceEntryCreation =
    Decode.succeed ReferenceEntryCreation |> required "referenceMapId" Uuid.decoder |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceEntryCreation : ReferenceEntryCreation -> Encode.Value
encoderReferenceEntryCreation obj =
    Encode.object [ ( "referenceMapId", Uuid.encode obj.referenceMapId ), ( "nutrientCode", Encode.int obj.nutrientCode ), ( "amount", Encode.float obj.amount ) ]
