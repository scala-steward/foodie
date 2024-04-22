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
    , profile : Profile
    }


type alias Initial =
    { meal : Pages.MealEntries.Meal.Page.Initial
    , entries : Pages.MealEntries.Entries.Page.Initial
    , profile : Maybe Profile
    , profileId : ProfileId
    }


initial : AuthorizedAccess -> ProfileId -> MealId -> Model
initial authorizedAccess profId mealId =
    { meal = Pages.Util.Parent.Page.initialWith authorizedAccess.jwt
    , entries = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt mealId
    , profile = Nothing
    , profileId = profId
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map3
        Main
        (i.meal |> Pages.Util.Parent.Page.initialToMain)
        (i.entries |> Pages.Util.Choice.Page.initialToMain)
        i.profile


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , profileId : ProfileId
    , mealId : MealId
    }


lenses :
    { initial :
        { meal : Lens Initial Pages.MealEntries.Meal.Page.Initial
        , entries : Lens Initial Pages.MealEntries.Entries.Page.Initial
        , profile : Lens Initial (Maybe Profile)
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
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    , main =
        { meal = Lens .meal (\b a -> { a | meal = b })
        , entries = Lens .entries (\b a -> { a | entries = b })
        }
    }


profileId : Model -> Maybe ProfileId
profileId =
    Tristate.fold
        { onInitial = .profileId >> Just
        , onMain = .profile >> .id >> Just
        , onError = always Nothing
        }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = MealMsg Pages.MealEntries.Meal.Page.LogicMsg
    | EntriesMsg Pages.MealEntries.Entries.Page.LogicMsg
    | GotFetchProfileResponse (Result Error Profile)
