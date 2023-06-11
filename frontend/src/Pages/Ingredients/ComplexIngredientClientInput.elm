module Pages.Ingredients.ComplexIngredientClientInput exposing (..)

import Api.Auxiliary exposing (ComplexFoodId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.ScalingMode as ScalingMode exposing (ScalingMode)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexIngredientClientInput =
    { complexFoodId : ComplexFoodId
    , factor : ValidatedInput Float
    , scalingMode : ScalingMode
    }


lenses :
    { factor : Lens ComplexIngredientClientInput (ValidatedInput Float)
    , scalingMode : Lens ComplexIngredientClientInput ScalingMode
    }
lenses =
    { factor = Lens .factor (\b a -> { a | factor = b })
    , scalingMode = Lens .scalingMode (\b a -> { a | scalingMode = b })
    }


from : ComplexIngredient -> ComplexIngredientClientInput
from complexIngredient =
    { complexFoodId = complexIngredient.complexFoodId
    , factor =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set complexIngredient.factor
            |> ValidatedInput.lenses.text.set (complexIngredient.factor |> String.fromFloat)
    , scalingMode = ScalingMode.Recipe
    }


fromFood : ComplexFood -> ComplexIngredientClientInput
fromFood complexFood =
    { complexFoodId = complexFood.recipeId
    , factor = ValidatedInput.positive
    , scalingMode = ScalingMode.Recipe
    }


to : ComplexIngredientClientInput -> ComplexIngredient
to input =
    { complexFoodId = input.complexFoodId
    , factor = input.factor.value
    , scalingMode = input.scalingMode
    }
