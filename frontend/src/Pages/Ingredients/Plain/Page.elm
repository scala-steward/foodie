module Pages.Ingredients.Plain.Page exposing (..)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Pages.Util.Choice.ChoiceGroup as ChoiceGroup
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Initial =
    ChoiceGroup.Initial IngredientId Ingredient IngredientUpdateClientInput FoodId Food


type alias Main =
    ChoiceGroup.Main IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput


type alias LogicMsg =
    ChoiceGroup.LogicMsg IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput
