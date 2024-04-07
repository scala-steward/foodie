module Pages.MealEntries.View exposing (view)

import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, div, label, text)
import Pages.MealEntries.Entries.View
import Pages.MealEntries.Meal.View
import Pages.MealEntries.Page as Page
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
        , jwt = .meal >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        main
    <|
        div [ Style.ids.mealEntryEditor ]
            [ div []
                [ Pages.MealEntries.Meal.View.viewMain main.profile.id configuration main.meal
                    |> Html.map Page.MealMsg
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Dishes" ] ]
            , Pages.MealEntries.Entries.View.viewMealEntries configuration main.entries |> Html.map Page.EntriesMsg
            , div [ Style.classes.elements ] [ label [] [ text "Recipes" ] ]
            , Pages.MealEntries.Entries.View.viewRecipes configuration main.entries |> Html.map Page.EntriesMsg
            ]
