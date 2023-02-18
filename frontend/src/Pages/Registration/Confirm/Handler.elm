module Pages.Registration.Confirm.Handler exposing (init, update)

import Pages.Registration.Confirm.Page as Page
import Pages.Registration.Confirm.Requests as Requests
import Pages.Util.ComplementInput exposing (ComplementInput)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetComplementInput complementInput ->
            setComplementInput model complementInput

        Page.Request ->
            request model

        Page.GotResponse result ->
            gotResponse model result


setComplementInput : Page.Model -> ComplementInput -> ( Page.Model, Cmd Page.Msg )
setComplementInput model complementInput =
    ( model |> Tristate.mapMain (Page.lenses.main.complementInput.set complementInput)
    , Cmd.none
    )


request : Page.Model -> ( Page.Model, Cmd Page.Msg )
request model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.request model.configuration
                    main.registrationJWT
                    { password = main.complementInput.passwordInput.password1
                    , displayName = main.complementInput.displayName
                    }
            )
    )


gotResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotResponse model result =
    ( result
        |> Result.Extra.unpack
            (Tristate.toError model)
            (\_ -> model |> Tristate.mapMain (Page.lenses.main.mode.set Page.Confirmed))
    , Cmd.none
    )
