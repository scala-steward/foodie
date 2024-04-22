module Pages.Profiles.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ProfileId)
import Api.Types.Profile exposing (decoderProfile)
import Api.Types.ProfileCreation exposing (ProfileCreation, encoderProfileCreation)
import Api.Types.ProfileUpdate exposing (ProfileUpdate)
import Http
import Pages.Profiles.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Util.HttpUtil as HttpUtil


fetchProfiles : AuthorizedAccess -> Cmd Page.LogicMsg
fetchProfiles =
    Pages.Util.Requests.fetchProfilesWith Pages.Util.ParentEditor.Page.GotFetchResponse


createProfile : AuthorizedAccess -> ProfileCreation -> Cmd Page.LogicMsg
createProfile authorizedAccess referenceMapCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.profiles.create
        { body = encoderProfileCreation referenceMapCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Pages.Util.ParentEditor.Page.GotCreateResponse decoderProfile
        }


saveProfile :
    AuthorizedAccess
    -> ProfileId
    -> ProfileUpdate
    -> Cmd Page.LogicMsg
saveProfile =
    Pages.Util.Requests.saveProfileWith Pages.Util.ParentEditor.Page.GotSaveEditResponse


deleteProfile :
    AuthorizedAccess
    -> ProfileId
    -> Cmd Page.LogicMsg
deleteProfile authorizedAccess referenceMapId =
    Pages.Util.Requests.deleteProfileWith (Pages.Util.ParentEditor.Page.GotDeleteResponse referenceMapId)
        authorizedAccess
        referenceMapId
