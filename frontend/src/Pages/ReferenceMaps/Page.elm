module Pages.ReferenceMaps.Page exposing (..)

import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Pages.ReferenceMaps.ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.ParentEditor.Page.Main ReferenceMapId ReferenceMap ReferenceMapCreationClientInput ReferenceMapUpdateClientInput


type alias Initial =
    Pages.Util.ParentEditor.Page.Initial ReferenceMapId ReferenceMap ReferenceMapUpdateClientInput


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type alias LogicMsg =
    Pages.Util.ParentEditor.Page.LogicMsg ReferenceMapId ReferenceMap ReferenceMapCreationClientInput ReferenceMapUpdateClientInput
