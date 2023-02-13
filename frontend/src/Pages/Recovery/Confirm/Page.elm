module Pages.Recovery.Confirm.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.PasswordInput as PasswordInput exposing (PasswordInput)
import Pages.View.Tristate as Tristate exposing (Tristate)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate Main Initial


type alias Main =
    { recoveryJwt : JWT
    , userIdentifier : UserIdentifier
    , passwordInput : PasswordInput
    , mode : Mode
    }


type alias Initial =
    ()


initial : Flags -> Model
initial flags =
    { recoveryJwt = flags.recoveryJwt
    , userIdentifier = flags.userIdentifier
    , passwordInput = PasswordInput.initial
    , mode = Resetting
    }
        |> Tristate.createMain flags.configuration


lenses :
    { main :
        { passwordInput : Lens Main PasswordInput
        , mode : Lens Main Mode
        }
    }
lenses =
    { main =
        { passwordInput = Lens .passwordInput (\b a -> { a | passwordInput = b })
        , mode = Lens .mode (\b a -> { a | mode = b })
        }
    }


type Mode
    = Resetting
    | Confirmed


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , recoveryJwt : JWT
    }


type Msg
    = SetPasswordInput PasswordInput
    | Confirm
    | GotConfirmResponse (Result Error ())
