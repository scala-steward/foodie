module Pages.Util.NavigationUtil exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (MealId, RecipeId)
import Configuration exposing (Configuration)
import Html exposing (Html, text)
import Pages.Util.Links as Links
import Pages.Util.Style as Style


recipeEditorLinkButton : Configuration -> RecipeId -> Html msg
recipeEditorLinkButton configuration recipeId =
    Links.linkButton
        { url =
            recipeId
                |> Addresses.Frontend.ingredientEditor.address
                |> Links.frontendPage configuration
        , attributes = [ Style.classes.button.editor ]
        , children = [ text "Recipe" ]
        }


recipeNutrientsLinkButton : Configuration -> RecipeId -> Html msg
recipeNutrientsLinkButton configuration recipeId =
    Links.linkButton
        { url =
            recipeId
                |> Addresses.Frontend.statisticsRecipeSelect.address
                |> Links.frontendPage configuration
        , attributes = [ Style.classes.button.nutrients ]
        , children = [ text "Nutrients" ]
        }

mealEditorLinkButton : Configuration -> RecipeId -> Html msg
mealEditorLinkButton configuration mealId =
    Links.linkButton
        { url =
            mealId
                |> Addresses.Frontend.mealEntryEditor.address
                |> Links.frontendPage configuration
        , attributes = [ Style.classes.button.editor ]
        , children = [ text "Meal" ]
        }

mealNutrientsLinkButton : Configuration -> MealId -> Html msg
mealNutrientsLinkButton configuration mealId =
    Links.linkButton
        { url =
            mealId
                |> Addresses.Frontend.statisticsMealSelect.address
                |> Links.frontendPage configuration
        , attributes = [ Style.classes.button.nutrients ]
        , children = [ text "Nutrients" ]
        }
