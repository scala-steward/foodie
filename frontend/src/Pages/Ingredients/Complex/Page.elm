module Pages.Ingredients.Complex.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.Choice.Page.Main RecipeId ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput


type alias Initial =
    Pages.Util.Choice.Page.Initial RecipeId ComplexIngredientId ComplexIngredient ComplexFoodId ComplexFood


type alias LogicMsg =
    Pages.Util.Choice.Page.LogicMsg ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput
