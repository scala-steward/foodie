module Pages.Recipes.Page exposing (..)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Pages.Recipes.RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    Pages.Util.ParentEditor.Page.Main RecipeId Recipe RecipeCreationClientInput RecipeUpdateClientInput


type alias Initial =
    Pages.Util.ParentEditor.Page.Initial RecipeId Recipe RecipeUpdateClientInput


type alias RecipeState =
    Editing Recipe RecipeUpdateClientInput


type alias RecipeStateMap =
    DictList RecipeId RecipeState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type alias ParentMsg =
    Pages.Util.ParentEditor.Page.LogicMsg RecipeId Recipe RecipeCreationClientInput RecipeUpdateClientInput


type LogicMsg
    = ParentMsg ParentMsg
    | Rescale RecipeId
    | GotRescaleResponse (Result Error Recipe)
