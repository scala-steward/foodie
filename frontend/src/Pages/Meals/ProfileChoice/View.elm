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

        -- todo: This has the unfortunate side effect of <unknown> on the settings button. Rethink the approach.
        -- In reality, we only need the JWT for the user name extraction, but this is a hack.
        -- Instead, we could either drop the name entirely, or use a more consistent approach.
        , jwt = always Nothing
        , currentPage = Just ViewUtil.Meals
        , showNavigation = True
        }
        main
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
