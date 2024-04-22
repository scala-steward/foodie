module Pages.Profiles.ProfileUpdateClientInput exposing (..)

import Api.Types.Profile exposing (Profile)
import Api.Types.ProfileUpdate exposing (ProfileUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ProfileUpdateClientInput =
    { name : ValidatedInput String
    }


lenses :
    { name : Lens ProfileUpdateClientInput (ValidatedInput String)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    }


fromProfile : Profile -> ProfileUpdateClientInput
fromProfile profile =
    { name =
        ValidatedInput.nonEmptyString
            |> ValidatedInput.lenses.value.set profile.name
            |> ValidatedInput.lenses.text.set profile.name
    }


toUpdate : ProfileUpdateClientInput -> ProfileUpdate
toUpdate input =
    { name = input.name.value
    }
