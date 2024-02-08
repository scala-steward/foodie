module Pages.MealEntries.MealEntryCreationClientInput exposing (..)

import Api.Auxiliary exposing (MealId, RecipeId)
import Api.Types.MealEntryCreation exposing (MealEntryCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealEntryCreationClientInput =
    { recipeId : RecipeId
    , numberOfServings : ValidatedInput Float
    }


lenses : { numberOfServings : Lens MealEntryCreationClientInput (ValidatedInput Float) }
lenses =
    { numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    }


default : RecipeId -> MealEntryCreationClientInput
default recipeId =
    { recipeId = recipeId
    , numberOfServings = ValidatedInput.positive
    }


toCreation : MealId -> MealEntryCreationClientInput -> MealEntryCreation
toCreation mealId input =
    { mealId = mealId
    , recipeId = input.recipeId
    , numberOfServings = input.numberOfServings.value
    }
