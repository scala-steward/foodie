module Pages.Meals.Editor.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealId, ProfileId)
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Monocle.Lens exposing (Lens)
import Pages.Meals.Editor.MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Editor.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { parentEditor : Pages.Util.ParentEditor.Page.Main MealId Meal MealCreationClientInput MealUpdateClientInput
    , profile : Profile
    }



-- todo: It is very questionable that the profile id is stored in parallel with the profile, because the profile
--       can have a different id from the profile id in theory.
--       The profile id here is only relevant for the case of updating the initial state, because the automation viw
--       updateLogic needs a profile id to call the corresponding editing functions.
--       However, none of these functions is called in the case of the initialization of the page.


type alias Initial =
    { parentEditor : Pages.Util.ParentEditor.Page.Initial MealId Meal MealUpdateClientInput
    , profile : Maybe Profile
    , profileId : ProfileId
    }


lenses :
    { initial :
        { parentEditor : Lens Initial (Pages.Util.ParentEditor.Page.Initial MealId Meal MealUpdateClientInput)
        , profile : Lens Initial (Maybe Profile)
        }
    , main :
        { parentEditor : Lens Main (Pages.Util.ParentEditor.Page.Main MealId Meal MealCreationClientInput MealUpdateClientInput)
        , profile : Lens Main Profile
        }
    }
lenses =
    { initial =
        { parentEditor = Lens .parentEditor (\b a -> { a | parentEditor = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    , main =
        { parentEditor = Lens .parentEditor (\b a -> { a | parentEditor = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , profileId : ProfileId
    }


initialToMain : Initial -> Maybe Main
initialToMain initial =
    Maybe.map2
        (\parentEditor profile ->
            { parentEditor = parentEditor
            , profile = profile
            }
        )
        (initial.parentEditor |> Pages.Util.ParentEditor.Page.initialToMain)
        initial.profile


profileId : Model -> Maybe ProfileId
profileId =
    Tristate.fold
        { onInitial = .profileId >> Just
        , onMain = .profile >> .id >> Just
        , onError = always Nothing
        }


type alias Msg =
    Tristate.Msg LogicMsg


type alias ParentLogicMsg =
    Pages.Util.ParentEditor.Page.LogicMsg MealId Meal MealCreationClientInput MealUpdateClientInput


type LogicMsg
    = ParentEditorMsg ParentLogicMsg
    | GotFetchProfileResponse (Result Error Profile)
