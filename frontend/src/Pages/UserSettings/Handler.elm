module Pages.UserSettings.Handler exposing (init, update)

import Addresses.Frontend
import Api.Types.Mode exposing (Mode)
import Api.Types.User exposing (User)
import Browser.Navigation
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Pages.UserSettings.Page as Page
import Pages.UserSettings.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ComplementInput as ComplementInput exposing (ComplementInput)
import Pages.Util.Links as Links
import Pages.Util.PasswordInput as PasswordInput
import Pages.View.Tristate as Tristate
import Ports
import Result.Extra
import Util.HttpUtil exposing (Error)


initialFetch : AuthorizedAccess -> Cmd Page.Msg
initialFetch =
    Requests.fetchUser


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.GotFetchUserResponse result ->
            gotFetchUserResponse model result

        Page.UpdatePassword ->
            updatePassword model

        Page.GotUpdatePasswordResponse result ->
            gotUpdatePasswordResponse model result

        Page.UpdateSettings ->
            updateSettings model

        Page.GotUpdateSettingsResponse result ->
            gotUpdateSettingsResponse model result

        Page.RequestDeletion ->
            requestDeletion model

        Page.GotRequestDeletionResponse result ->
            gotRequestDeletionResponse model result

        Page.SetComplementInput complementInput ->
            setComplementInput model complementInput

        Page.Logout logoutKind ->
            logout model logoutKind

        Page.GotLogoutResponse result ->
            gotLogoutResponse model result


gotFetchUserResponse : Page.Model -> Result Error User -> ( Page.Model, Cmd Page.Msg )
gotFetchUserResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\user ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.user.set (Just user))
                    |> Tristate.fromInitToMain Page.initialToMain
                    |> Tristate.mapMain ((Page.lenses.main.complementInput |> Compose.lensWithLens ComplementInput.lenses.displayName).set user.displayName)
            )
    , Cmd.none
    )


updatePassword : Page.Model -> ( Page.Model, Cmd Page.Msg )
updatePassword model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.updatePassword
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    { password = main.complementInput.passwordInput.password1 }
            )
    )


gotUpdatePasswordResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotUpdatePasswordResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\_ ->
                model
                    |> Tristate.mapMain
                        (Lens.modify Page.lenses.main.complementInput
                            (ComplementInput.lenses.passwordInput.set PasswordInput.initial)
                        )
            )
    , Cmd.none
    )


updateSettings : Page.Model -> ( Page.Model, Cmd Page.Msg )
updateSettings model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.updateSettings
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    { displayName = main.complementInput.displayName }
            )
    )


gotUpdateSettingsResponse : Page.Model -> Result Error User -> ( Page.Model, Cmd Page.Msg )
gotUpdateSettingsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\user -> model |> Tristate.mapMain (Page.lenses.main.user.set user))
    , Cmd.none
    )


requestDeletion : Page.Model -> ( Page.Model, Cmd Page.Msg )
requestDeletion model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.requestDeletion
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
            )
    )


gotRequestDeletionResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotRequestDeletionResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\_ -> model |> Tristate.mapMain (Page.lenses.main.mode.set Page.RequestedDeletion))
    , Cmd.none
    )


setComplementInput : Page.Model -> ComplementInput -> ( Page.Model, Cmd Page.Msg )
setComplementInput model complementInput =
    ( model |> Tristate.mapMain (Page.lenses.main.complementInput.set complementInput)
    , Cmd.none
    )


logout : Page.Model -> Api.Types.Mode.Mode -> ( Page.Model, Cmd Page.Msg )
logout model mode =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.logout
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    mode
            )
    )


gotLogoutResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotLogoutResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model.configuration error, Cmd.none ))
            (\_ ->
                ( model
                , Cmd.batch
                    [ Ports.doDeleteToken ()
                    , ()
                        |> Addresses.Frontend.login.address
                        |> Links.frontendPage model.configuration
                        |> Browser.Navigation.load
                    ]
                )
            )
