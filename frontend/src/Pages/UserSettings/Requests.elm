module Pages.UserSettings.Requests exposing (..)

import Addresses.Backend
import Api.Types.LogoutRequest exposing (encoderLogoutRequest)
import Api.Types.Mode exposing (Mode)
import Api.Types.PasswordChangeRequest exposing (PasswordChangeRequest, encoderPasswordChangeRequest)
import Api.Types.User exposing (decoderUser)
import Api.Types.UserUpdate exposing (UserUpdate, encoderUserUpdate)
import Http
import Pages.UserSettings.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchUser : AuthorizedAccess -> Cmd Page.LogicMsg
fetchUser authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.users.get
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchUserResponse decoderUser
        }


updatePassword : AuthorizedAccess -> PasswordChangeRequest -> Cmd Page.LogicMsg
updatePassword authorizedAccess passwordChangeRequest =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.users.updatePassword
        { body = encoderPasswordChangeRequest passwordChangeRequest |> Http.jsonBody
        , expect = HttpUtil.expectWhatever Page.GotUpdatePasswordResponse
        }


updateSettings : AuthorizedAccess -> UserUpdate -> Cmd Page.LogicMsg
updateSettings authorizedAccess userUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.users.update
        { body = encoderUserUpdate userUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotUpdateSettingsResponse decoderUser
        }


requestDeletion : AuthorizedAccess -> Cmd Page.LogicMsg
requestDeletion authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.users.deletion.request
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever Page.GotRequestDeletionResponse
        }


logout : AuthorizedAccess -> Mode -> Cmd Page.LogicMsg
logout authorizedAccess mode =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.users.logout
        { body = encoderLogoutRequest { mode = mode } |> Http.jsonBody
        , expect = HttpUtil.expectWhatever Page.GotLogoutResponse
        }
