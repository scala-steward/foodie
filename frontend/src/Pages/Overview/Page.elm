module Pages.Overview.Page exposing (..)

import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Pages.View.Tristate as Tristate exposing (Tristate)


type alias Model =
    Tristate () ()


type alias Main =
    ()


type alias Initial =
    ()


initial : Configuration -> Model
initial =
    flip Tristate.createInitial ()


type alias Msg =
    ()


type alias Flags =
    { configuration : Configuration
    }
