module Pages.ReferenceEntries.Map.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.ReferenceMap exposing (decoderReferenceMap)
import Http
import Pages.ReferenceEntries.Map.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Page
import Util.HttpUtil as HttpUtil


fetchReferenceMap : AuthorizedAccess -> ReferenceMapId -> Cmd Page.LogicMsg
fetchReferenceMap authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.single referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.Parent.Page.GotFetchResponse decoderReferenceMap
        }
