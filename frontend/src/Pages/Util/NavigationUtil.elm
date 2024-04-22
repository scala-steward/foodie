module Pages.Util.NavigationUtil exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (MealId, ProfileId, RecipeId)
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
    nutrientButtonWith
        { address =
            recipeId
                |> Addresses.Frontend.statisticsRecipeSelect.address
                |> Links.frontendPage configuration
        }


mealEditorLinkButton : Configuration -> ProfileId -> MealId -> Html msg
mealEditorLinkButton configuration profileId mealId =
    Links.linkButton
        { url =
            ( profileId, mealId )
                |> Addresses.Frontend.mealEntryEditor.address
                |> Links.frontendPage configuration
        , attributes = [ Style.classes.button.editor ]
        , children = [ text "Meal" ]
        }


mealNutrientsLinkButton : Configuration -> ProfileId -> MealId -> Html msg
mealNutrientsLinkButton configuration profileId mealId =
    nutrientButtonWith
        { address =
            ( profileId, mealId )
                |> Addresses.Frontend.statisticsMealSelect.address
                |> Links.frontendPage configuration
        }


complexFoodNutrientLinkButton : Configuration -> RecipeId -> Html msg
complexFoodNutrientLinkButton configuration recipeId =
    nutrientButtonWith
        { address =
            recipeId
                |> Addresses.Frontend.statisticsComplexFoodSelect.address
                |> Links.frontendPage configuration
        }


nutrientButtonWith : { address : String } -> Html msg
nutrientButtonWith ps =
    Links.linkButton
        { url = ps.address
        , attributes = [ Style.classes.button.nutrients ]
        , children = [ text "Nutrients" ]
        }
