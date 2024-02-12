module Pages.ComplexFoods.ComplexFoodCreationClientInput exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Api.Types.ComplexFoodIncoming exposing (ComplexFoodIncoming)
import Api.Types.Recipe exposing (Recipe)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Util
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Parser exposing ((|.), (|=))


type alias ComplexFoodCreationClientInput =
    { recipeId : RecipeId
    , amountGrams : ValidatedInput Float
    , amountMilliLitres : ValidatedInput (Maybe Float)
    }


withSuggestion : Recipe -> ComplexFoodCreationClientInput
withSuggestion recipe =
    let
        modifier =
            recipe.servingSize
                |> Maybe.andThen (Parser.run Pages.Recipes.Util.gramsParser >> Result.toMaybe)
                |> Maybe.map ((*) recipe.numberOfServings)
                |> Maybe.Extra.unwrap identity
                    (\value ->
                        ValidatedInput.lenses.value.set value
                            >> ValidatedInput.lenses.text.set (String.fromFloat value)
                    )
    in
    { recipeId = recipe.id
    , amountGrams = ValidatedInput.positive |> modifier
    , amountMilliLitres = ValidatedInput.maybePositive
    }


to : ComplexFoodCreationClientInput -> ComplexFoodIncoming
to input =
    { recipeId = input.recipeId
    , amountGrams = input.amountGrams.value
    , amountMilliLitres = input.amountMilliLitres.value
    }


lenses :
    { amountGrams : Lens ComplexFoodCreationClientInput (ValidatedInput Float)
    , amountMilliLitres : Lens ComplexFoodCreationClientInput (ValidatedInput (Maybe Float))
    }
lenses =
    { amountGrams = Lens .amountGrams (\b a -> { a | amountGrams = b })
    , amountMilliLitres = Lens .amountMilliLitres (\b a -> { a | amountMilliLitres = b })
    }
