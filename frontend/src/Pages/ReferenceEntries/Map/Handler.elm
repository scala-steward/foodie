module Pages.ReferenceEntries.Map.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (ReferenceMapId)
import Pages.ReferenceEntries.Map.Page as Page
import Pages.ReferenceEntries.Map.Requests as Requests
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Handler
import Pages.Util.Parent.Page
import Pages.Util.Requests


initialFetch : AuthorizedAccess -> ReferenceMapId -> Cmd Page.LogicMsg
initialFetch =
    Requests.fetchReferenceMap


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Parent.Handler.updateLogic
        { toUpdate = ReferenceMapUpdateClientInput.from
        , idOf = .id
        , save =
            \authorizedAccess update ->
                update
                    |> ReferenceMapUpdateClientInput.to
                    |> (\referenceMapUpdate ->
                            Pages.Util.Requests.saveReferenceMapWith
                                Pages.Util.Parent.Page.GotSaveEditResponse
                                { authorizedAccess = authorizedAccess
                                , referenceMapUpdate = referenceMapUpdate
                                }
                       )
                    |> Just
        , delete =
            \authorizedAccess referenceMapId ->
                Pages.Util.Requests.deleteReferenceMapWith Pages.Util.Parent.Page.GotDeleteResponse
                    { authorizedAccess = authorizedAccess
                    , referenceMapId = referenceMapId
                    }
        , navigateAfterDeletionAddress = Addresses.Frontend.referenceMaps.address
        }
