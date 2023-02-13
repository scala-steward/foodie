module Pages.Login.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.Credentials exposing (Credentials)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main ()


type alias Main =
    { credentials : Credentials
    }


lenses :
    { main :
        { credentials : Lens Main Credentials
        }
    }
lenses =
    { main =
        { credentials = Lens .credentials (\b a -> { a | credentials = b })
        }
    }


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = SetNickname String
    | SetPassword String
    | Login
    | GotResponse (Result Error JWT)
