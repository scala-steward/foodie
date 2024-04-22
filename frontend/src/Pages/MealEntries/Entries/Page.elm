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


type alias Initial =
    Pages.Util.Choice.Page.Initial MealId MealEntryId MealEntry RecipeId Recipe


type alias Main =
    Pages.Util.Choice.Page.Main MealId MealEntryId MealEntry MealEntryUpdateClientInput RecipeId Recipe MealEntryCreationClientInput


type alias LogicMsg =
    Pages.Util.Choice.Page.LogicMsg MealEntryId MealEntry MealEntryUpdateClientInput RecipeId Recipe MealEntryCreationClientInput
