module Pages.Ingredients.ComplexIngredientCreationClientInput exposing (..)

import Api.Auxiliary exposing (ComplexFoodId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredientCreation exposing (ComplexIngredientCreation)
import Api.Types.ScalingMode as ScalingMode exposing (ScalingMode)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexIngredientCreationClientInput =
    { complexFoodId : ComplexFoodId
    , factor : ValidatedInput Float
    , scalingMode : ScalingMode
    }


lenses :
    { factor : Lens ComplexIngredientCreationClientInput (ValidatedInput Float)
    , scalingMode : Lens ComplexIngredientCreationClientInput ScalingMode
    }
lenses =
    { factor = Lens .factor (\b a -> { a | factor = b })
    , scalingMode = Lens .scalingMode (\b a -> { a | scalingMode = b })
    }


default : ComplexFoodId -> ComplexIngredientCreationClientInput
default complexFoodId =
    { complexFoodId = complexFoodId
    , factor = ValidatedInput.positive
    , scalingMode = ScalingMode.Recipe
    }


from : ComplexFood -> ComplexIngredientCreationClientInput
from =
    .recipeId >> default


to : ComplexIngredientCreationClientInput -> ComplexIngredientCreation
to input =
    { complexFoodId = input.complexFoodId
    , factor = input.factor.value
    , scalingMode = input.scalingMode
    }
