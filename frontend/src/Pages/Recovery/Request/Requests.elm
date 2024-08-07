module Pages.Recovery.Request.Requests exposing (find, requestRecovery)

import Addresses.Backend
import Api.Auxiliary exposing (UserId)
import Api.Types.RecoveryRequest exposing (encoderRecoveryRequest)
import Api.Types.User exposing (decoderUser)
import Configuration exposing (Configuration)
import Http
import Json.Decode as Decode
import Pages.Recovery.Request.Page as Page
import Util.HttpUtil as HttpUtil


find : Configuration -> String -> Cmd Page.LogicMsg
find configuration searchString =
    HttpUtil.runPattern
        configuration
        (Addresses.Backend.users.recovery.find searchString)
        { jwt = Nothing
        , body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFindResponse (Decode.list decoderUser)
        }


requestRecovery : Configuration -> UserId -> Cmd Page.LogicMsg
requestRecovery configuration userId =
    HttpUtil.runPattern
        configuration
        Addresses.Backend.users.recovery.request
        { jwt = Nothing
        , body = encoderRecoveryRequest { userId = userId } |> Http.jsonBody
        , expect = HttpUtil.expectWhatever Page.GotRequestRecoveryResponse
        }
