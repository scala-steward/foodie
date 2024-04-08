module Pages.Meals.ProfileChoice.View exposing (..)

import Addresses.Frontend
import Api.Types.Profile exposing (Profile)
import Configuration exposing (Configuration)
import Html exposing (Html, li, menu, text)
import Pages.Meals.ProfileChoice.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , currentPage = Just ViewUtil.Meals
        , showNavigation = True
        }
    <|
        menu []
            (List.map (viewProfileButton configuration) main.profiles)


viewProfileButton : Configuration -> Profile -> Html Page.LogicMsg
viewProfileButton configuration profile =
    li []
        [ Links.linkButton
            { url = Links.frontendPage configuration <| Addresses.Frontend.meals.address profile.id
            , attributes = [ Style.classes.button.overview ]
            , children = [ text profile.name ]
            }
        ]
