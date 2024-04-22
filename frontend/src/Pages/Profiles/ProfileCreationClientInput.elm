module Pages.Profiles.ProfileCreationClientInput exposing (..)

import Api.Types.ProfileCreation exposing (ProfileCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ProfileCreationClientInput =
    { name : ValidatedInput String
    }


default : ProfileCreationClientInput
default =
    { name = ValidatedInput.nonEmptyString
    }


lenses :
    { name : Lens ProfileCreationClientInput (ValidatedInput String)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    }


toCreation : ProfileCreationClientInput -> ProfileCreation
toCreation input =
    { name = input.name.value
    }
