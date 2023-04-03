module Pages.ReferenceEntries.Map.Page exposing (..)

import Api.Types.ReferenceMap exposing (ReferenceMap)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.Parent.Page.Main ReferenceMap ReferenceMapUpdateClientInput


type alias Initial =
    Pages.Util.Parent.Page.Initial ReferenceMap


type alias LogicMsg =
    Pages.Util.Parent.Page.LogicMsg ReferenceMap ReferenceMapUpdateClientInput
