module Pages.ReferenceEntries.Requests exposing
    ( addReferenceEntry
    , deleteReferenceEntry
    , fetchNutrients
    , fetchReferenceEntries
    , fetchReferenceMap
    , saveReferenceEntry
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (decoderNutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry, decoderReferenceEntry)
import Api.Types.ReferenceEntryCreation exposing (ReferenceEntryCreation, encoderReferenceEntryCreation)
import Api.Types.ReferenceEntryUpdate exposing (ReferenceEntryUpdate, encoderReferenceEntryUpdate)
import Api.Types.ReferenceMap exposing (decoderReferenceMap)
import Http
import Json.Decode as Decode
import Pages.ReferenceEntries.Page as Page exposing (LogicMsg(..))
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil






fetchReferenceMap : AuthorizedAccess -> ReferenceMapId -> Cmd Page.LogicMsg
fetchReferenceMap authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.single referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchReferenceMapResponse decoderReferenceMap
        }




