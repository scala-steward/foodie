module Pages.Registration.Request.Handler exposing (init, update)

import Pages.Registration.Request.Page as Page
import Pages.Registration.Request.Requests as Requests
import Pages.Util.ValidatedInput exposing (ValidatedInput)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.configuration
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.SetNickname nickname ->
            setNickname model nickname

        Page.SetEmail email ->
            setEmail model email

        Page.Request ->
            request model

        Page.GotRequestResponse result ->
            gotRequestResponse model result


setNickname : Page.Model -> ValidatedInput String -> ( Page.Model, Cmd Page.LogicMsg )
setNickname model nickname =
    ( model |> Tristate.mapMain (Page.lenses.main.nickname.set nickname)
    , Cmd.none
    )


setEmail : Page.Model -> ValidatedInput String -> ( Page.Model, Cmd Page.LogicMsg )
setEmail model email =
    ( model |> Tristate.mapMain (Page.lenses.main.email.set email)
    , Cmd.none
    )


request : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
request model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.request
                    model.configuration
                    { nickname = main.nickname.value
                    , email = main.email.value
                    }
            )
    )


gotRequestResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotRequestResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\_ -> model |> Tristate.mapMain (Page.lenses.main.mode.set Page.Confirmed))
    , Cmd.none
    )
