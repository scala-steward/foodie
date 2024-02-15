module Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (..)

import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceEntryUpdate exposing (ReferenceEntryUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceEntryUpdateClientInput =
    { amount : ValidatedInput Float
    }


lenses : { amount : Lens ReferenceEntryUpdateClientInput (ValidatedInput Float) }
lenses =
    { amount = Lens .amount (\b a -> { a | amount = b })
    }


from : ReferenceEntry -> ReferenceEntryUpdateClientInput
from referenceEntry =
    { amount =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set referenceEntry.amount
            |> ValidatedInput.lenses.text.set (referenceEntry.amount |> String.fromFloat)
    }


to : ReferenceEntryUpdateClientInput -> ReferenceEntryUpdate
to input =
    { amount = input.amount.value
    }
