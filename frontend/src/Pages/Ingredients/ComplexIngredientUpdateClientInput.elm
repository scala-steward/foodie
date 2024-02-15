module Pages.Ingredients.ComplexIngredientUpdateClientInput exposing (..)

import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.ComplexIngredientUpdate exposing (ComplexIngredientUpdate)
import Api.Types.ScalingMode exposing (ScalingMode)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexIngredientUpdateClientInput =
    { factor : ValidatedInput Float
    , scalingMode : ScalingMode
    }


lenses :
    { factor : Lens ComplexIngredientUpdateClientInput (ValidatedInput Float)
    , scalingMode : Lens ComplexIngredientUpdateClientInput ScalingMode
    }
lenses =
    { factor = Lens .factor (\b a -> { a | factor = b })
    , scalingMode = Lens .scalingMode (\b a -> { a | scalingMode = b })
    }


from : ComplexIngredient -> ComplexIngredientUpdateClientInput
from complexIngredient =
    { factor =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set complexIngredient.factor
            |> ValidatedInput.lenses.text.set (complexIngredient.factor |> String.fromFloat)
    , scalingMode = complexIngredient.scalingMode
    }


to : ComplexIngredientUpdateClientInput -> ComplexIngredientUpdate
to input =
    { factor = input.factor.value
    , scalingMode = input.scalingMode
    }
