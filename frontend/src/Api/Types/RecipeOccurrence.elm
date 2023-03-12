module Api.Types.RecipeOccurrence exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Recipe exposing (..)
import Api.Types.Meal exposing (..)

type alias RecipeOccurrence = { recipe: Recipe, lastUsedInMeal: (Maybe Meal) }


decoderRecipeOccurrence : Decode.Decoder RecipeOccurrence
decoderRecipeOccurrence = Decode.succeed RecipeOccurrence |> required "recipe" (Decode.lazy (\_ -> decoderRecipe)) |> optional "lastUsedInMeal" (Decode.maybe (Decode.lazy (\_ -> decoderMeal))) Nothing


encoderRecipeOccurrence : RecipeOccurrence -> Encode.Value
encoderRecipeOccurrence obj = Encode.object [ ("recipe", encoderRecipe obj.recipe), ("lastUsedInMeal", Maybe.withDefault Encode.null (Maybe.map encoderMeal obj.lastUsedInMeal)) ]