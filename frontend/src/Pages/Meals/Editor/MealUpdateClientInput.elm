module Pages.Meals.Editor.MealUpdateClientInput exposing (..)

import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Pages.Util.SimpleDateInput as SimpleDateInput exposing (SimpleDateInput)


type alias MealUpdateClientInput =
    { date : SimpleDateInput
    , name : Maybe String
    }


lenses :
    { date : Lens MealUpdateClientInput SimpleDateInput
    , name : Optional MealUpdateClientInput String
    }
lenses =
    { date = Lens .date (\b a -> { a | date = b })
    , name = Optional .name (\b a -> { a | name = Just b |> Maybe.Extra.filter (String.isEmpty >> not) })
    }


from : Meal -> MealUpdateClientInput
from meal =
    { date = meal.date |> SimpleDateInput.from
    , name = meal.name
    }


to : MealUpdateClientInput -> Maybe MealUpdate
to input =
    input.date
        |> SimpleDateInput.to
        |> Maybe.map
            (\simpleDate ->
                { date = simpleDate
                , name = input.name
                }
            )
