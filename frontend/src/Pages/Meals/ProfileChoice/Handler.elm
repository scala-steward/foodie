module Pages.Meals.ProfileChoice.Handler exposing (..)

import Pages.Meals.ProfileChoice.Page as Page
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Result.Extra


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess.configuration
    , Pages.Util.Requests.fetchProfilesWith
        Page.GotFetchProfilesResponse
        flags.authorizedAccess
        |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.GotFetchProfilesResponse result ->
            result
                |> Result.Extra.unpack
                    (\error -> ( Tristate.toError model error, Cmd.none ))
                    --todo: In case there is precisely one profile, we should directly navigate to the next page
                    (\profiles ->
                        ( Tristate.mapInitial (Page.lenses.initial.profiles.set (Just profiles)) model
                            |> Tristate.fromInitToMain Page.initialToMain
                        , Cmd.none
                        )
                    )
