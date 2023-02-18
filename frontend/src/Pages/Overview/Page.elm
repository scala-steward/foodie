module Pages.Overview.Page exposing (..)

import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model () ()


type alias Main =
    ()


type alias Initial =
    ()


initial : Configuration -> Model
initial =
    flip Tristate.createMain ()


type alias Msg =
    Tristate.Msg LogicMsg


type alias LogicMsg =
    ()


type alias Flags =
    { configuration : Configuration
    }
