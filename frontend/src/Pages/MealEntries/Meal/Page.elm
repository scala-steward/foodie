module Pages.MealEntries.Meal.Page exposing (..)

import Api.Auxiliary exposing (ProfileId)
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial



--todo: "parent" is a bad choice, because 'Main' contains a parent, too


type alias Main =
    { parent : Pages.Util.Parent.Page.Main Meal MealUpdateClientInput
    , profile : Profile
    }



--todo: "parent" is a bad choice, because 'Main' contains a parent, too


type alias Initial =
    { parent : Pages.Util.Parent.Page.Initial Meal
    , profile : Maybe Profile
    }


lenses :
    { initial :
        { parent : Lens Initial (Pages.Util.Parent.Page.Initial Meal)
        , profile : Lens Initial (Maybe Profile)
        }
    , main :
        { parent : Lens Main (Pages.Util.Parent.Page.Main Meal MealUpdateClientInput)
        , profile : Lens Main Profile
        }
    }
lenses =
    { initial =
        { parent = Lens .parent (\b a -> { a | parent = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    , main =
        { parent = Lens .parent (\b a -> { a | parent = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    }


initialToMain : Initial -> Maybe Main
initialToMain initial =
    Maybe.map2
        (\parent profile ->
            { parent = parent
            , profile = profile
            }
        )
        (initial.parent |> Pages.Util.Parent.Page.initialToMain)
        initial.profile


profileId : Model -> Maybe ProfileId
profileId =
    Tristate.fold
        { onInitial = .profile >> Maybe.map .id
        , onMain = .profile >> .id >> Just
        , onError = always Nothing
        }


type LogicMsg
    = ParentMsg (Pages.Util.Parent.Page.LogicMsg Meal MealUpdateClientInput)
    | GotFetchProfileResponse (Result Error Profile)
