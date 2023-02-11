module Pages.Deletion.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.View.Tristate exposing (Tristate)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    Tristate Main ()


type alias Main =
    { deletionJWT : JWT
    , userIdentifier : UserIdentifier
    , mode : Mode
    }


lenses :
    { main :
        { mode : Lens Main Mode
        }
    }
lenses =
    { main =
        { mode = Lens .mode (\b a -> { a | mode = b })
        }
    }


type Mode
    = Checking
    | Confirmed


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , deletionJWT : JWT
    }


type Msg
    = Confirm
    | GotConfirmResponse (Result Error ())
