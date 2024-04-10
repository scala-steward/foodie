module Pages.Util.ProfileChoice.View exposing (viewWith)

import Api.Auxiliary exposing (ProfileId)
import Api.Types.Profile exposing (Profile)
import Configuration exposing (Configuration)
import Html exposing (Html, li, menu, text)
import Pages.Util.Links as Links
import Pages.Util.ProfileChoice.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


type alias Directions =
    { address : ProfileId -> List String }


viewWith : Directions -> Page.Model -> Html Page.Msg
viewWith ps =
    Tristate.view
        { viewMain = viewMainWith ps
        , showLoginRedirect = True
        }


viewMainWith : Directions -> Configuration -> Page.Main -> Html Page.LogicMsg
viewMainWith ps configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , currentPage = Just ViewUtil.MealsProfileChoice
        , showNavigation = True
        }
    <|
        menu []
            (List.map (viewProfileButtonWith ps configuration) main.profiles)


viewProfileButtonWith : Directions -> Configuration -> Profile -> Html Page.LogicMsg
viewProfileButtonWith ps configuration profile =
    li []
        [ Links.linkButton
            { url = Links.frontendPage configuration <| ps.address <| .id <| profile
            , attributes = [ Style.classes.button.overview ]
            , children = [ text profile.name ]
            }
        ]
