module Pages.Profiles.Page exposing (..)

import Api.Auxiliary exposing (ProfileId)
import Api.Types.Profile exposing (Profile)
import Pages.Profiles.ProfileCreationClientInput exposing (ProfileCreationClientInput)
import Pages.Profiles.ProfileUpdateClientInput exposing (ProfileUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.ParentEditor.Page.Main ProfileId Profile ProfileCreationClientInput ProfileUpdateClientInput


type alias Initial =
    Pages.Util.ParentEditor.Page.Initial ProfileId Profile ProfileUpdateClientInput


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type alias LogicMsg =
    Pages.Util.ParentEditor.Page.LogicMsg ProfileId Profile ProfileCreationClientInput ProfileUpdateClientInput
