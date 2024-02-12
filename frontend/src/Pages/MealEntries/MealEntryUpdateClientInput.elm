module Pages.MealEntries.MealEntryUpdateClientInput exposing (..)

import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealEntryUpdateClientInput =
    { numberOfServings : ValidatedInput Float
    }


lenses : { numberOfServings : Lens MealEntryUpdateClientInput (ValidatedInput Float) }
lenses =
    { numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    }


from : MealEntry -> MealEntryUpdateClientInput
from mealEntry =
    { numberOfServings =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set mealEntry.numberOfServings
            |> ValidatedInput.lenses.text.set (mealEntry.numberOfServings |> String.fromFloat)
    }


to : MealEntryUpdateClientInput -> MealEntryUpdate
to input =
    { numberOfServings = input.numberOfServings.value
    }
