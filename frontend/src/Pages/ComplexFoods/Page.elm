module Pages.ComplexFoods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, JWT, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Foods.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , foods : Pages.ComplexFoods.Foods.Page.Main
    }


type alias Initial =
    { jwt : JWT
    , foods : Pages.ComplexFoods.Foods.Page.Initial
    }


foodsSubModel : Model -> Pages.ComplexFoods.Foods.Page.Model
foodsSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.foods
        , mainLens = lenses.main.foods
        }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , foods = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt ()
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.foods
        |> Pages.Util.Choice.Page.initialToMain
        |> Maybe.map
            (\foods ->
                { jwt = i.jwt
                , foods = foods
                }
            )


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


lenses :
    { initial :
        { foods : Lens Initial Pages.ComplexFoods.Foods.Page.Initial
        }
    , main :
        { foods : Lens Main Pages.ComplexFoods.Foods.Page.Main
        }
    }
lenses =
    { initial =
        { foods = Lens .foods (\b a -> { a | foods = b })
        }
    , main =
        { foods = Lens .foods (\b a -> { a | foods = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = FoodsMsg Pages.ComplexFoods.Foods.Page.LogicMsg
