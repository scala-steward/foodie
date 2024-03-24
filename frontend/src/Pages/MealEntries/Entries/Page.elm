module Pages.MealEntries.Entries.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, ProfileId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Profile exposing (Profile)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.MealEntries.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial



--todo: "choices" is a bad choice, because 'Main' contains a choices, too


type alias Initial =
    { choices : Pages.Util.Choice.Page.Initial MealId MealEntryId MealEntry RecipeId Recipe
    , profile : Maybe Profile
    }



--todo: "choices" is a bad choice, because 'Main' contains a choices, too


type alias Main =
    { choices : Pages.Util.Choice.Page.Main MealId MealEntryId MealEntry MealEntryUpdateClientInput RecipeId Recipe MealEntryCreationClientInput
    , profile : Profile
    }


lenses :
    { initial :
        { choices : Lens Initial (Pages.Util.Choice.Page.Initial MealId MealEntryId MealEntry RecipeId Recipe)
        , profile : Lens Initial (Maybe Profile)
        }
    , main :
        { choices : Lens Main (Pages.Util.Choice.Page.Main MealId MealEntryId MealEntry MealEntryUpdateClientInput RecipeId Recipe MealEntryCreationClientInput)
        , profile : Lens Main Profile
        }
    }
lenses =
    { initial =
        { choices = Lens .choices (\b a -> { a | choices = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    , main =
        { choices = Lens .choices (\b a -> { a | choices = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    }


initialToMain : Initial -> Maybe Main
initialToMain initial =
    Maybe.map2
        (\choices profile ->
            { choices = choices
            , profile = profile
            }
        )
        (initial.choices |> Pages.Util.Choice.Page.initialToMain)
        initial.profile


profileId : Model -> Maybe ProfileId
profileId =
    Tristate.fold
        { onInitial = .profile >> Maybe.map .id
        , onMain = .profile >> .id >> Just
        , onError = always Nothing
        }


type alias ChoiceLogicMsg =
    Pages.Util.Choice.Page.LogicMsg MealEntryId MealEntry MealEntryUpdateClientInput RecipeId Recipe MealEntryCreationClientInput


type LogicMsg
    = ChoiceMsg ChoiceLogicMsg
    | GotFetchProfileResponse (Result Error Profile)
