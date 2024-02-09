module Pages.Recipes.RecipeUpdateClientInput exposing (..)

import Api.Types.Recipe exposing (Recipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias RecipeUpdateClientInput =
    { name : ValidatedInput String
    , description : Maybe String
    , numberOfServings : ValidatedInput Float
    , servingSize : Maybe String
    }


lenses :
    { name : Lens RecipeUpdateClientInput (ValidatedInput String)
    , description : Lens RecipeUpdateClientInput (Maybe String)
    , numberOfServings : Lens RecipeUpdateClientInput (ValidatedInput Float)
    , servingSize : Lens RecipeUpdateClientInput (Maybe String)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    , description = Lens .description (\b a -> { a | description = b })
    , numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    , servingSize = Lens .servingSize (\b a -> { a | servingSize = b })
    }


from : Recipe -> RecipeUpdateClientInput
from recipe =
    { name =
        ValidatedInput.nonEmptyString
            |> ValidatedInput.lenses.value.set recipe.name
            |> ValidatedInput.lenses.text.set recipe.name
    , description = recipe.description
    , numberOfServings =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set recipe.numberOfServings
            |> ValidatedInput.lenses.text.set (recipe.numberOfServings |> String.fromFloat)
    , servingSize = recipe.servingSize
    }


to : RecipeUpdateClientInput -> RecipeUpdate
to input =
    { name = input.name.value
    , description = input.description
    , numberOfServings = input.numberOfServings.value
    , servingSize = input.servingSize
    }
