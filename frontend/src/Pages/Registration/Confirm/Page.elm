module Pages.Registration.Confirm.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.ComplementInput as ComplementInput exposing (ComplementInput)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main ()


type alias Main =
    { userIdentifier : UserIdentifier
    , complementInput : ComplementInput
    , registrationJWT : JWT
    , mode : Mode
    }


initial : Flags -> Model
initial flags =
    { userIdentifier = flags.userIdentifier
    , complementInput = ComplementInput.initial
    , registrationJWT = flags.registrationJWT
    , mode = Editing
    }
        |> Tristate.createMain flags.configuration


lenses :
    { main :
        { complementInput : Lens Main ComplementInput
        , mode : Lens Main Mode
        }
    }
lenses =
    { main =
        { complementInput = Lens .complementInput (\b a -> { a | complementInput = b })
        , mode = Lens .mode (\b a -> { a | mode = b })
        }
    }


type Mode
    = Editing
    | Confirmed


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , registrationJWT : JWT
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = SetComplementInput ComplementInput
    | Request
    | GotResponse (Result Error ())
