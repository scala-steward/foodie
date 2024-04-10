module Pages.Meals.ProfileChoice.View exposing (..)

import Addresses.Frontend
import Html exposing (Html)
import Pages.Meals.ProfileChoice.Page as Page
import Pages.Util.ProfileChoice.View
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    Pages.Util.ProfileChoice.View.viewWith
        { address = Addresses.Frontend.meals.address
        , currentPage = ViewUtil.MealsProfileChoice
        }
        model
