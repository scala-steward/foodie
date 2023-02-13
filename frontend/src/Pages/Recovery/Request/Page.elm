module Pages.Recovery.Request.Page exposing (..)

import Api.Auxiliary exposing (UserId)
import Api.Types.User exposing (User)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { users : List User
    , searchString : String
    , mode : Mode
    }


type alias Initial =
    ()


initial : Configuration -> Model
initial configuration =
    { users = []
    , searchString = ""
    , mode = Initial
    }
        |> Tristate.createMain configuration


type Mode
    = Initial
    | Requesting
    | Requested


lenses :
    { main :
        { users : Lens Main (List User)
        , searchString : Lens Main String
        , mode : Lens Main Mode
        }
    }
lenses =
    { main =
        { users = Lens .users (\b a -> { a | users = b })
        , searchString = Lens .searchString (\b a -> { a | searchString = b })
        , mode = Lens .mode (\b a -> { a | mode = b })
        }
    }


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = Find
    | GotFindResponse (Result Error (List User))
    | SetSearchString String
    | RequestRecovery UserId
    | GotRequestRecoveryResponse (Result Error ())
