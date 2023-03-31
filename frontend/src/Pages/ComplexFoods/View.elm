module Pages.ComplexFoods.View exposing (..)

import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, div, label, text)
import Pages.ComplexFoods.Foods.View
import Pages.ComplexFoods.Page as Page
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
        , jwt = .jwt >> Just
        , currentPage = Just ViewUtil.ComplexFoods
        , showNavigation = True
        }
        main
    <|
        div [ Style.ids.complexFoodEditor ]
            [ div [ Style.classes.elements ] [ label [] [ text "Complex foods" ] ]
            , Pages.ComplexFoods.Foods.View.viewComplexFoods configuration main.foods |> Html.map Page.FoodsMsg
            , div [ Style.classes.elements ] [ label [] [ text "Recipes" ] ]
            , Pages.ComplexFoods.Foods.View.viewRecipes configuration main.foods |> Html.map Page.FoodsMsg
            ]
