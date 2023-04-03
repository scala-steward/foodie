module Pages.ReferenceEntries.Entries.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode, RecipeId, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Initial =
    Pages.Util.Choice.Page.Initial ReferenceMapId NutrientCode ReferenceEntry NutrientCode Nutrient


type alias Main =
    Pages.Util.Choice.Page.Main ReferenceMapId NutrientCode ReferenceEntry ReferenceEntryUpdateClientInput NutrientCode Nutrient ReferenceEntryCreationClientInput


type alias LogicMsg =
    Pages.Util.Choice.Page.LogicMsg NutrientCode ReferenceEntry ReferenceEntryUpdateClientInput NutrientCode Nutrient ReferenceEntryCreationClientInput
