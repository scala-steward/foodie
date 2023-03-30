module Pages.ReferenceEntries.Entries.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (decoderNutrient)
import Api.Types.ReferenceEntry exposing (decoderReferenceEntry)
import Api.Types.ReferenceEntryCreation exposing (ReferenceEntryCreation, encoderReferenceEntryCreation)
import Api.Types.ReferenceEntryUpdate exposing (ReferenceEntryUpdate, encoderReferenceEntryUpdate)
import Http
import Json.Decode as Decode
import Pages.ReferenceEntries.Entries.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Util.HttpUtil as HttpUtil


fetchReferenceEntries : AuthorizedAccess -> ReferenceMapId -> Cmd Page.LogicMsg
fetchReferenceEntries authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.entries.allOf referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotFetchElementsResponse (Decode.list decoderReferenceEntry)
        }


createReferenceEntry : AuthorizedAccess -> ReferenceEntryCreation -> Cmd Page.LogicMsg
createReferenceEntry authorizedAccess referenceNutrientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.entries.create
        { body = encoderReferenceEntryCreation referenceNutrientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotCreateResponse decoderReferenceEntry
        }


saveReferenceEntry : AuthorizedAccess -> ReferenceEntryUpdate -> Cmd Page.LogicMsg
saveReferenceEntry authorizedAccess referenceEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.entries.update
        { body = encoderReferenceEntryUpdate referenceEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotSaveEditResponse decoderReferenceEntry
        }


deleteReferenceEntry : AuthorizedAccess -> ReferenceMapId -> NutrientCode -> Cmd Page.LogicMsg
deleteReferenceEntry authorizedAccess referenceMapId nutrientCode =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.entries.delete referenceMapId nutrientCode)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Pages.Util.Choice.Page.GotDeleteResponse nutrientCode)
        }


fetchNutrients : AuthorizedAccess -> Cmd Page.LogicMsg
fetchNutrients authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.nutrients
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Pages.Util.Choice.Page.GotFetchChoicesResponse (Decode.list decoderNutrient)
        }
