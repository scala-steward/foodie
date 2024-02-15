module Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (..)

import Api.Types.ReferenceMap exposing (ReferenceMap)
import Api.Types.ReferenceMapUpdate exposing (ReferenceMapUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceMapUpdateClientInput =
    { name : ValidatedInput String
    }


lenses :
    { name : Lens ReferenceMapUpdateClientInput (ValidatedInput String)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    }


from : ReferenceMap -> ReferenceMapUpdateClientInput
from referenceMap =
    { name =
        ValidatedInput.nonEmptyString
            |> ValidatedInput.lenses.value.set referenceMap.name
            |> ValidatedInput.lenses.text.set referenceMap.name
    }


to : ReferenceMapUpdateClientInput -> ReferenceMapUpdate
to input =
    { name = input.name.value
    }
