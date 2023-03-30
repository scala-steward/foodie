module Pages.ComplexFoods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, JWT, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Pages.ComplexFoods.ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias Model =
    Tristate.Model Main Initial


type alias Initial =
    Pages.Util.Choice.Page.Initial () ComplexFoodId ComplexFood RecipeId Recipe


type alias Main =
    Pages.Util.Choice.Page.Main () ComplexFoodId ComplexFood ComplexFoodClientInput RecipeId Recipe ComplexFoodClientInput


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    Pages.Util.Choice.Page.initialWith authorizedAccess.jwt ()
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain =
    Pages.Util.Choice.Page.initialToMain


type alias ComplexFoodState =
    Editing ComplexFood ComplexFoodClientInput


type alias ComplexFoodStateMap =
    DictList ComplexFoodId ComplexFoodState


type alias CreateComplexFoodsMap =
    DictList ComplexFoodId ComplexFoodClientInput


type alias RecipeState =
    Editing Recipe ComplexFoodClientInput


type alias RecipeStateMap =
    DictList RecipeId RecipeState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type alias LogicMsg =
    Pages.Util.Choice.Page.LogicMsg ComplexFoodId ComplexFood ComplexFoodClientInput RecipeId Recipe ComplexFoodClientInput
