module Pages.Recovery.Confirm.Handler exposing (init, update)

import Pages.Recovery.Confirm.Page as Page
import Pages.Recovery.Confirm.Requests as Requests
import Pages.Util.PasswordInput as PasswordInput exposing (PasswordInput)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.SetPasswordInput passwordInput ->
            setPasswordInput model passwordInput

        Page.Confirm ->
            confirm model

        Page.GotConfirmResponse result ->
            gotConfirmResponse model result


setPasswordInput : Page.Model -> PasswordInput -> ( Page.Model, Cmd Page.LogicMsg )
setPasswordInput model passwordInput =
    ( model |> Tristate.mapMain (Page.lenses.main.passwordInput.set passwordInput)
    , Cmd.none
    )


confirm : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
confirm model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.confirm
                    { configuration = model.configuration
                    , recoveryJwt = main.recoveryJwt
                    , password = main.passwordInput.password1
                    }
            )
    )


gotConfirmResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotConfirmResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\_ ->
                model
                    |> Tristate.mapMain
                        (Page.lenses.main.mode.set Page.Confirmed
                            >> Page.lenses.main.passwordInput.set PasswordInput.initial
                        )
            )
    , Cmd.none
    )
