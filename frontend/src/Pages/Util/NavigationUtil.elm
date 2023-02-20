module Pages.Util.NavigationUtil exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (RecipeId)
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
