module Pages.ReferenceMaps.Requests exposing (createReferenceMap, deleteReferenceMap, fetchReferenceMaps, saveReferenceMap)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap, decoderReferenceMap)
import Api.Types.ReferenceMapCreation exposing (ReferenceMapCreation, encoderReferenceMapCreation)
import Api.Types.ReferenceMapUpdate exposing (ReferenceMapUpdate)
import Http
import Json.Decode as Decode
import Pages.ReferenceMaps.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchReferenceMaps : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceMaps authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.ParentEditor.Page.GotFetchResponse (Decode.list decoderReferenceMap)
        }


createReferenceMap : AuthorizedAccess -> ReferenceMapCreation -> Cmd Page.LogicMsg
createReferenceMap authorizedAccess referenceMapCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.create
        { body = encoderReferenceMapCreation referenceMapCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.ParentEditor.Page.GotCreateResponse decoderReferenceMap
        }


saveReferenceMap :
    AuthorizedAccess
    -> ReferenceMapUpdate
    -> Cmd Page.LogicMsg
saveReferenceMap authorizedAccess referenceMapUpdate =
    Pages.Util.Requests.saveReferenceMapWith Pages.Util.ParentEditor.Page.GotSaveEditResponse
        { authorizedAccess = authorizedAccess
        , referenceMapUpdate = referenceMapUpdate
        }


deleteReferenceMap :
    AuthorizedAccess
    -> ReferenceMapId
    -> Cmd Page.LogicMsg
deleteReferenceMap authorizedAccess referenceMapId =
    Pages.Util.Requests.deleteReferenceMapWith (Pages.Util.ParentEditor.Page.GotDeleteResponse referenceMapId)
        { authorizedAccess = authorizedAccess
        , referenceMapId = referenceMapId
        }
