module Pages.Ingredients.Plain.Page exposing (..)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, RecipeId)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Util.Choice.Page as ChoiceGroup
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Initial =
    ChoiceGroup.Initial RecipeId IngredientId Ingredient FoodId Food


type alias Main =
    ChoiceGroup.Main RecipeId IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput


type alias LogicMsg =
    ChoiceGroup.LogicMsg IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput
