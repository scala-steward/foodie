module Pages.Util.ProfileChoice.Page exposing (..)

import Api.Types.Profile exposing (Profile)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { profiles : List Profile
    }


type alias Initial =
    { profiles : Maybe (List Profile)
    }


lenses :
    { initial :
        { profiles : Lens Initial (Maybe (List Profile))
        }
    , main :
        { profiles : Lens Main (List Profile)
        }
    }
lenses =
    { initial =
        { profiles = Lens .profiles (\b a -> { a | profiles = b })
        }
    , main =
        { profiles = Lens .profiles (\b a -> { a | profiles = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


initial : Configuration -> Model
initial =
    { profiles = Nothing
    }
        |> flip Tristate.createInitial


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.profiles
        |> Maybe.map (\p -> { profiles = p })


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = GotFetchProfilesResponse (Result Error (List Profile))
