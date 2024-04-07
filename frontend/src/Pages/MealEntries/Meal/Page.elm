module Pages.MealEntries.Meal.Page exposing (..)

import Api.Types.Meal exposing (Meal)
import Pages.Meals.Editor.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.Parent.Page.Main Meal MealUpdateClientInput


type alias Initial =
    Pages.Util.Parent.Page.Initial Meal


type alias LogicMsg =
    Pages.Util.Parent.Page.LogicMsg Meal MealUpdateClientInput
