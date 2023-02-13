module Pages.Recovery.Request.Handler exposing (init, update)

import Api.Auxiliary exposing (UserId)
import Api.Types.User exposing (User)
import Pages.Recovery.Request.Page as Page
import Pages.Recovery.Request.Requests as Requests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.configuration
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.Find ->
            find model

        Page.GotFindResponse result ->
            gotFindResponse model result

        Page.SetSearchString string ->
            setSearchString model string

        Page.RequestRecovery userId ->
            requestRecovery model userId

        Page.GotRequestRecoveryResponse result ->
            gotRequestRecoveryResponse model result


find : Page.Model -> ( Page.Model, Cmd Page.Msg )
find model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (.searchString >> Requests.find model.configuration)
    )


gotFindResponse : Page.Model -> Result Error (List User) -> ( Page.Model, Cmd Page.Msg )
gotFindResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model.configuration error, Cmd.none ))
            (\users ->
                case users of
                    user :: [] ->
                        requestRecovery model user.id

                    _ ->
                        ( model
                            |> Tristate.mapMain
                                (Page.lenses.main.users.set users
                                    >> Page.lenses.main.mode.set Page.Requesting
                                )
                        , Cmd.none
                        )
            )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model
        |> Tristate.mapMain
            (Page.lenses.main.searchString.set string
                >> Page.lenses.main.mode.set Page.Initial
            )
    , Cmd.none
    )


requestRecovery : Page.Model -> UserId -> ( Page.Model, Cmd Page.Msg )
requestRecovery model userId =
    ( model
    , Requests.requestRecovery model.configuration userId
    )


gotRequestRecoveryResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotRequestRecoveryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\_ -> model |> Tristate.mapMain (Page.lenses.main.mode.set Page.Requested))
    , Cmd.none
    )
