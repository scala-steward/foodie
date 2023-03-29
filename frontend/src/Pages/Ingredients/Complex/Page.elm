module Pages.Ingredients.Complex.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Util.Choice.ChoiceGroup as ChoiceGroup
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    ChoiceGroup.Main ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput


type alias Initial =
    ChoiceGroup.Initial ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood


type alias LogicMsg =
    ChoiceGroup.LogicMsg ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput
