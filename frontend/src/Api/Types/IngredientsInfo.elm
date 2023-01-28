module Api.Types.IngredientsInfo exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Ingredient exposing (..)

type alias IngredientsInfo = { ingredients: (List Ingredient), weightInGrams: Float }


decoderIngredientsInfo : Decode.Decoder IngredientsInfo
decoderIngredientsInfo = Decode.succeed IngredientsInfo |> required "ingredients" (Decode.list (Decode.lazy (\_ -> decoderIngredient))) |> required "weightInGrams" Decode.float


encoderIngredientsInfo : IngredientsInfo -> Encode.Value
encoderIngredientsInfo obj = Encode.object [ ("ingredients", Encode.list encoderIngredient obj.ingredients), ("weightInGrams", Encode.float obj.weightInGrams) ]