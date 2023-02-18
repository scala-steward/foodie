module Pages.Deletion.Handler exposing (init, update)

import Pages.Deletion.Page as Page
import Pages.Deletion.Requests as Requests
import Pages.View.Tristate as Tristate
import Ports
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { deletionJWT = flags.deletionJWT
      , userIdentifier = flags.userIdentifier
      , mode = Page.Checking
      }
        |> Tristate.createMain flags.configuration
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.Confirm ->
            confirm model

        Page.GotConfirmResponse result ->
            gotConfirmResponse model result


confirm : Page.Model -> ( Page.Model, Cmd Page.Msg )
confirm model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (.deletionJWT
                >> Requests.deleteUser model.configuration
            )
    )


gotConfirmResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotConfirmResponse model result =
    result
        |> Result.Extra.unpack
            (\error ->
                ( error |> Tristate.toError model
                , Cmd.none
                )
            )
            (\_ ->
                ( model |> Tristate.mapMain (Page.lenses.main.mode.set Page.Confirmed)
                , Ports.doDeleteToken ()
                )
            )
