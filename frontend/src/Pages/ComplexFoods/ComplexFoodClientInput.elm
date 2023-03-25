module Pages.ComplexFoods.ComplexFoodClientInput exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodIncoming exposing (ComplexFoodIncoming)
import Api.Types.Recipe exposing (Recipe)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexFoodClientInput =
    { recipeId : RecipeId
    , amountGrams : ValidatedInput Float
    , amountMilliLitres : ValidatedInput (Maybe Float)
    }


default : RecipeId -> ComplexFoodClientInput
default recipeId =
    { recipeId = recipeId
    , amountGrams = ValidatedInput.positive
    , amountMilliLitres = ValidatedInput.maybePositive
    }


withSuggestion : Recipe -> ComplexFoodClientInput
withSuggestion recipe =
    let
        modifier =
            recipe.servingSize
                |> Maybe.Extra.filter ((==) "100g")
                |> Maybe.map (\_ -> 100 * recipe.numberOfServings)
                |> Maybe.Extra.unwrap identity ValidatedInput.lenses.value.set
    in
    { recipeId = recipe.id
    , amountGrams = ValidatedInput.positive |> modifier
    , amountMilliLitres = ValidatedInput.maybePositive
    }


from : ComplexFood -> ComplexFoodClientInput
from complexFood =
    { recipeId = complexFood.recipeId
    , amountGrams =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set complexFood.amountGrams
            |> ValidatedInput.lenses.text.set (complexFood.amountGrams |> String.fromFloat)
    , amountMilliLitres =
        ValidatedInput.maybePositive
            |> ValidatedInput.lenses.value.set complexFood.amountMilliLitres
            |> ValidatedInput.lenses.text.set (complexFood.amountMilliLitres |> Maybe.Extra.unwrap "" String.fromFloat)
    }


to : ComplexFoodClientInput -> ComplexFoodIncoming
to input =
    { recipeId = input.recipeId
    , amountGrams = input.amountGrams.value
    , amountMilliLitres = input.amountMilliLitres.value
    }


lenses :
    { amountGrams : Lens ComplexFoodClientInput (ValidatedInput Float)
    , amountMilliLitres : Lens ComplexFoodClientInput (ValidatedInput (Maybe Float))
    }
lenses =
    { amountGrams = Lens .amountGrams (\b a -> { a | amountGrams = b })
    , amountMilliLitres = Lens .amountMilliLitres (\b a -> { a | amountMilliLitres = b })
    }
