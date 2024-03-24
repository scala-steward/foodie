module Pages.MealEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, ProfileId, RecipeId)
import Api.Types.Profile exposing (Profile)
import Monocle.Lens exposing (Lens)
import Pages.MealEntries.Entries.Page
import Pages.MealEntries.Meal.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { meal : Pages.MealEntries.Meal.Page.Main
    , entries : Pages.MealEntries.Entries.Page.Main
    }


type alias Initial =
    { meal : Pages.MealEntries.Meal.Page.Initial
    , entries : Pages.MealEntries.Entries.Page.Initial
    }


initial : AuthorizedAccess -> MealId -> Model
initial authorizedAccess mealId =
    { meal =
        { parent = Pages.Util.Parent.Page.initialWith authorizedAccess.jwt
        , profile = Nothing
        }
    , entries =
        { choices = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt mealId
        , profile = Nothing
        }
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.meal
        |> Pages.MealEntries.Meal.Page.initialToMain
        |> Maybe.andThen
            (\meal ->
                i.entries
                    |> Pages.MealEntries.Entries.Page.initialToMain
                    |> Maybe.map
                        (\entries ->
                            { meal = meal
                            , entries = entries
                            }
                        )
            )


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , profileId : ProfileId
    , mealId : MealId
    }


lenses :
    { initial :
        { meal : Lens Initial Pages.MealEntries.Meal.Page.Initial
        , entries : Lens Initial Pages.MealEntries.Entries.Page.Initial
        }
    , main :
        { meal : Lens Main Pages.MealEntries.Meal.Page.Main
        , entries : Lens Main Pages.MealEntries.Entries.Page.Main
        }
    }
lenses =
    { initial =
        { meal = Lens .meal (\b a -> { a | meal = b })
        , entries = Lens .entries (\b a -> { a | entries = b })
        }
    , main =
        { meal = Lens .meal (\b a -> { a | meal = b })
        , entries = Lens .entries (\b a -> { a | entries = b })
        }
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = MealMsg Pages.MealEntries.Meal.Page.LogicMsg
    | EntriesMsg Pages.MealEntries.Entries.Page.LogicMsg
    | GotFetchProfileResponse (Result Error Profile)
