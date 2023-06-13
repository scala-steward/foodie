module Api.Types.ScalingMode exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


type ScalingMode
    = Recipe
    | Weight
    | Volume



-- todo: Consider a more automatic approach


decoderScalingMode : Decode.Decoder ScalingMode
decoderScalingMode =
    Decode.string |> Decode.andThen decoderScalingModeByString


decoderScalingModeByString : String -> Decode.Decoder ScalingMode
decoderScalingModeByString string =
    case string of
        "Recipe" ->
            Decode.succeed Recipe

        "Weight" ->
            Decode.succeed Weight

        "Volume" ->
            Decode.succeed Volume

        _ ->
            Decode.fail ("Unexpected type for ScalingMode: " ++ string)


encoderScalingMode : ScalingMode -> Encode.Value
encoderScalingMode =
    toString >> Encode.string


toString : ScalingMode -> String
toString scalingMode =
    case scalingMode of
        Recipe ->
            "Recipe"

        Weight ->
            "Weight"

        Volume ->
            "Volume"


fromString : String -> Maybe ScalingMode
fromString string =
    case string of
        "Recipe" ->
            Just Recipe

        "Weight" ->
            Just Weight

        "Volume" ->
            Just Volume

        _ ->
            Nothing
