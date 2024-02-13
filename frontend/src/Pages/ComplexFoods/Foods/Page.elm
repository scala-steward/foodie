module Pages.ComplexFoods.Foods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Pages.ComplexFoods.ComplexFoodCreationClientInput exposing (ComplexFoodCreationClientInput)
import Pages.ComplexFoods.ComplexFoodUpdateClientInput exposing (ComplexFoodUpdateClientInput)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Initial =
    Pages.Util.Choice.Page.Initial () ComplexFoodId ComplexFood RecipeId Recipe


type alias Main =
    Pages.Util.Choice.Page.Main () ComplexFoodId ComplexFood ComplexFoodUpdateClientInput RecipeId Recipe ComplexFoodCreationClientInput


type alias LogicMsg =
    Pages.Util.Choice.Page.LogicMsg ComplexFoodId ComplexFood ComplexFoodUpdateClientInput RecipeId Recipe ComplexFoodCreationClientInput
