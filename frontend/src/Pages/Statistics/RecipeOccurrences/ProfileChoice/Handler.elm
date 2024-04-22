module Pages.Statistics.RecipeOccurrences.ProfileChoice.Handler exposing (..)

import Pages.Meals.ProfileChoice.Page as Page
import Pages.Util.ProfileChoice.Handler


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init =
    Pages.Util.ProfileChoice.Handler.init


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Pages.Util.ProfileChoice.Handler.update
