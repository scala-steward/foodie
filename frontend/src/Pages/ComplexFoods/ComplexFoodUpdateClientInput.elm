module Pages.ComplexFoods.ComplexFoodUpdateClientInput exposing (..)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodUpdate exposing (ComplexFoodUpdate)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexFoodUpdateClientInput =
    { amountGrams : ValidatedInput Float
    , amountMilliLitres : ValidatedInput (Maybe Float)
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
