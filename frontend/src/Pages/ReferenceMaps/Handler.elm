module Pages.ReferenceMaps.Handler exposing (init, update)

import Addresses.Frontend
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Pages.ReferenceMaps.Page as Page
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.ReferenceMaps.Requests as Requests
import Pages.Util.ParentEditor.Handler
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Pages.View.Tristate as Tristate


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Pages.Util.ParentEditor.Page.initial flags.authorizedAccess
    , Requests.fetchReferenceMaps flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.ParentEditor.Handler.updateLogic
        { idOfParent = .id
        , idOfUpdate = .id
        , toUpdate = ReferenceMapUpdateClientInput.from
        , navigateToAddress = Addresses.Frontend.referenceEntries.address
        , create = \authorizedAccess -> ReferenceMapCreationClientInput.toCreation >> Requests.createReferenceMap authorizedAccess
        , save = \authorizedAccess -> ReferenceMapUpdateClientInput.to >> Requests.saveReferenceMap authorizedAccess
        , delete = Requests.deleteReferenceMap
        , duplicate = Pages.Util.Requests.duplicateReferenceMapWith Pages.Util.ParentEditor.Page.GotDuplicateResponse
        }
