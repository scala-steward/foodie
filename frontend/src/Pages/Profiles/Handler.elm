module Pages.Profiles.Handler exposing (..)

import Addresses.Frontend
import Pages.Profiles.Page as Page
import Pages.Profiles.ProfileCreationClientInput as ProfileCreationClientInput
import Pages.Profiles.ProfileUpdateClientInput as ProfileUpdateClientInput
import Pages.Profiles.Requests as Requests
import Pages.Util.ParentEditor.Handler
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Pages.Util.ParentEditor.Page.initial flags.authorizedAccess
    , Requests.fetchProfiles flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.ParentEditor.Handler.updateLogic
        { idOfParent = .id
        , toUpdate = ProfileUpdateClientInput.fromProfile
        , navigateToAddress = \_ -> Addresses.Frontend.profiles.address ()
        , updateCreationTimestamp = always identity
        , create = \authorizedAccess -> ProfileCreationClientInput.toCreation >> Requests.createProfile authorizedAccess
        , save = \authorizedAccess profileId -> ProfileUpdateClientInput.toUpdate >> Requests.saveProfile authorizedAccess profileId
        , delete = Requests.deleteProfile
        , duplicate = \_ _ _ -> Cmd.none
        , attemptInitialToMainAfterFetchResponse = True
        }
