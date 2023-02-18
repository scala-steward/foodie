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
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchReferenceMaps : AuthorizedAccess -> Cmd Page.LogicMsg
fetchReferenceMaps authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchReferenceMapsResponse (Decode.list decoderReferenceMap)
        }


createReferenceMap : AuthorizedAccess -> ReferenceMapCreation -> Cmd Page.LogicMsg
createReferenceMap authorizedAccess referenceMapCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.create
        { body = encoderReferenceMapCreation referenceMapCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateReferenceMapResponse decoderReferenceMap
        }


saveReferenceMap :
    { authorizedAccess : AuthorizedAccess
    , referenceMapUpdate : ReferenceMapUpdate
    }
    -> Cmd Page.LogicMsg
saveReferenceMap =
    Pages.Util.Requests.saveReferenceMapWith Page.GotSaveReferenceMapResponse


deleteReferenceMap :
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    }
    -> Cmd Page.LogicMsg
deleteReferenceMap ps =
    Pages.Util.Requests.deleteReferenceMapWith (Page.GotDeleteReferenceMapResponse ps.referenceMapId) ps
