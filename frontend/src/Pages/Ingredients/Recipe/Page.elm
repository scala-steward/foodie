module Pages.Ingredients.Recipe.Page exposing (..)

import Api.Types.Recipe exposing (Recipe)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.Parent.Page.Main Recipe RecipeUpdateClientInput


type alias Initial =
    Pages.Util.Parent.Page.Initial Recipe


type alias LogicMsg =
    Pages.Util.Parent.Page.LogicMsg Recipe RecipeUpdateClientInput
