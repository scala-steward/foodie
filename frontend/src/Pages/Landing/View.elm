module Pages.Landing.View exposing (view)

import Addresses.Frontend
import Html exposing (Html, article, h1, main_, nav, p, section, text)
import Pages.Util.Links as Links
import Pages.Util.Style as Style


view : Html msg
view =
    main_ [ Style.classes.confirm ]
        [ article []
            [ h1 [] [ text "Foodie" ]
            , section []
                [ p []
                    [ text "Track your meals, manage recipes, and monitor your nutrient intake." ]
                , p []
                    [ text "Create custom recipes, log daily meals, and view detailed nutritional statistics." ]
                ]
            ]
        , nav []
            [ Links.linkButton
                { url = Links.frontendPage <| Addresses.Frontend.login.address ()
                , attributes = [ Style.classes.button.confirm ]
                , children = [ text "Log in" ]
                }
            , Links.linkButton
                { url = Links.frontendPage <| Addresses.Frontend.requestRegistration.address ()
                , attributes = [ Style.classes.button.navigation ]
                , children = [ text "Create account" ]
                }
            ]
        ]
