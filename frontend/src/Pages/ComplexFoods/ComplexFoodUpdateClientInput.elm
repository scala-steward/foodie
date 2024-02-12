module Pages.ComplexFoods.ComplexFoodUpdateClientInput exposing (..)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodUpdate exposing (ComplexFoodUpdate)
import Api.Types.Recipe exposing (Recipe)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Util
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Parser exposing ((|.), (|=))


type alias ComplexFoodUpdateClientInput =
    { amountGrams : ValidatedInput Float
    , amountMilliLitres : ValidatedInput (Maybe Float)
    }


withSuggestion : Recipe -> ComplexFoodUpdateClientInput
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
    { amountGrams = ValidatedInput.positive |> modifier
    , amountMilliLitres = ValidatedInput.maybePositive
    }


from : ComplexFood -> ComplexFoodUpdateClientInput
from complexFood =
    { amountGrams =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set complexFood.amountGrams
            |> ValidatedInput.lenses.text.set (complexFood.amountGrams |> String.fromFloat)
    , amountMilliLitres =
        ValidatedInput.maybePositive
            |> ValidatedInput.lenses.value.set complexFood.amountMilliLitres
            |> ValidatedInput.lenses.text.set (complexFood.amountMilliLitres |> Maybe.Extra.unwrap "" String.fromFloat)
    }


to : ComplexFoodUpdateClientInput -> ComplexFoodUpdate
to input =
    { amountGrams = input.amountGrams.value
    , amountMilliLitres = input.amountMilliLitres.value
    }


lenses :
    { amountGrams : Lens ComplexFoodUpdateClientInput (ValidatedInput Float)
    , amountMilliLitres : Lens ComplexFoodUpdateClientInput (ValidatedInput (Maybe Float))
    }
lenses =
    { amountGrams = Lens .amountGrams (\b a -> { a | amountGrams = b })
    , amountMilliLitres = Lens .amountMilliLitres (\b a -> { a | amountMilliLitres = b })
    }
