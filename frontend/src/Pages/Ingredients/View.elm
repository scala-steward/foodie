module Pages.Ingredients.View exposing (view)

import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, div, label, text)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
import Pages.Ingredients.Complex.View
import Pages.Ingredients.Page as Page
import Pages.Ingredients.Plain.View
import Pages.Ingredients.Recipe.View
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
        , currentPage = Nothing
        , showNavigation = True
        }
        main
    <|
        div [ Style.ids.ingredientEditor ]
            [ div []
                [ Pages.Ingredients.Recipe.View.viewMain configuration main.recipe
                    |> Html.map Page.RecipeMsg
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Ingredients" ] ]
            , Pages.Ingredients.Plain.View.viewIngredients configuration main.ingredientsGroup |> Html.map Page.IngredientMsg
            , div [ Style.classes.elements ] [ label [] [ text "Complex ingredients" ] ]
            , Pages.Ingredients.Complex.View.viewMain configuration main.complexIngredientsGroup |> Html.map Page.ComplexIngredientMsg
            , div []
                [ button
                    [ disabled <| main.foodsMode == Page.Plain
                    , onClick <| Page.ChangeFoodsMode Page.Plain
                    , Style.classes.button.alternative
                    ]
                    [ text "Ingredients" ]
                , button
                    [ disabled <| main.foodsMode == Page.Complex
                    , onClick <| Page.ChangeFoodsMode Page.Complex
                    , Style.classes.button.alternative
                    ]
                    [ text "Complex ingredients" ]
                ]
            , case main.foodsMode of
                Page.Plain ->
                    Pages.Ingredients.Plain.View.viewFoods configuration main.ingredientsGroup |> Html.map Page.IngredientMsg

                Page.Complex ->
                    Pages.Ingredients.Complex.View.viewFoods configuration main.complexIngredientsGroup |> Html.map Page.ComplexIngredientMsg
            ]
