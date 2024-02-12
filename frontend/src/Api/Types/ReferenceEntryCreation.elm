module Api.Types.ReferenceEntryCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceEntryCreation =
    { nutrientCode : Int, amount : Float }


decoderReferenceEntryCreation : Decode.Decoder ReferenceEntryCreation
decoderReferenceEntryCreation =
    Decode.succeed ReferenceEntryCreation |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceEntryCreation : ReferenceEntryCreation -> Encode.Value
encoderReferenceEntryCreation obj =
    Encode.object [ ( "nutrientCode", Encode.int obj.nutrientCode ), ( "amount", Encode.float obj.amount ) ]
