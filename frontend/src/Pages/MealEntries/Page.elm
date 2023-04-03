module Pages.MealEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.MealEntries.Entries.Page
import Pages.MealEntries.Meal.Page
import Pages.MealEntries.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , meal : Pages.MealEntries.Meal.Page.Main
    , entries : Pages.MealEntries.Entries.Page.Main
    }


type alias Initial =
    { jwt : JWT
    , meal : Pages.MealEntries.Meal.Page.Initial
    , entries : Pages.MealEntries.Entries.Page.Initial
    }


mealSubModel : Model -> Pages.MealEntries.Meal.Page.Model
mealSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.meal
        , mainLens = lenses.main.meal
        }


entriesSubModel : Model -> Pages.MealEntries.Entries.Page.Model
entriesSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.entries
        , mainLens = lenses.main.entries
        }


initial : AuthorizedAccess -> MealId -> Model
initial authorizedAccess mealId =
    { jwt = authorizedAccess.jwt
    , meal = Pages.Util.Parent.Page.initialWith authorizedAccess.jwt
    , entries = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt mealId
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.meal
        |> Pages.Util.Parent.Page.initialToMain
        |> Maybe.andThen
            (\meal ->
                i.entries
                    |> Pages.Util.Choice.Page.initialToMain
                    |> Maybe.map
                        (\entries ->
                            { jwt = i.jwt
                            , meal = meal
                            , entries = entries
                            }
                        )
            )


type alias MealEntryState =
    Editing MealEntry MealEntryUpdateClientInput


type alias RecipeMap =
    DictList RecipeId Recipe


type alias AddMealEntriesMap =
    DictList RecipeId MealEntryCreationClientInput


type alias MealEntryStateMap =
    DictList MealEntryId MealEntryState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
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
