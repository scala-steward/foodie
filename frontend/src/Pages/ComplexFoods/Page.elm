module Pages.ComplexFoods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, JWT, RecipeId)
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.Foods.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate


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
