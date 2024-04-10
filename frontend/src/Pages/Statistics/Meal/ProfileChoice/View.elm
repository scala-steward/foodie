module Pages.Meals.ProfileChoice.View exposing (..)

import Addresses.Frontend
import Html exposing (Html)
import Pages.Meals.ProfileChoice.Page as Page
import Pages.Util.ProfileChoice.View


view : Page.Model -> Html Page.Msg
view =
    Pages.Util.ProfileChoice.View.viewWith
        { address = Addresses.Frontend.statisticsMealSearch.address
        }
