module Pages.Ingredients.Recipe.Page exposing (..)

import Api.Types.Recipe exposing (Recipe)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.Parent.Page.Main Recipe RecipeUpdateClientInput


type alias Initial =
    Pages.Util.Parent.Page.Initial Recipe


type alias ParentMsg =
    Pages.Util.Parent.Page.LogicMsg Recipe RecipeUpdateClientInput


type LogicMsg
    = ParentMsg ParentMsg
    | Rescale
    | GotRescaleResponse (Result Error Recipe)
