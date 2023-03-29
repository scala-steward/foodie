module Pages.Ingredients.Plain.Page exposing (..)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, RecipeId)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Initial =
    Pages.Util.Choice.Page.Initial RecipeId IngredientId Ingredient FoodId Food


type alias Main =
    Pages.Util.Choice.Page.Main RecipeId IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput


type alias LogicMsg =
    Pages.Util.Choice.Page.LogicMsg IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput
