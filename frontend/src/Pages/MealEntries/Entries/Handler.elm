module Pages.MealEntries.Entries.Handler exposing (..)

import Api.Auxiliary exposing (MealId)
import Pages.MealEntries.Entries.Page as Page
import Pages.MealEntries.Entries.Requests as Requests
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess mealId =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchMealEntries authorizedAccess mealId
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .id
        , idOfUpdate = .mealEntryId
        , idOfChoice = .id
        , choiceIdOfElement = .recipeId
        , choiceIdOfCreation = .recipeId
        , toUpdate = MealEntryUpdateClientInput.from
        , toCreation = \recipe -> MealEntryCreationClientInput.default recipe.id
        , createElement = \authorizedAccess mealId -> MealEntryCreationClientInput.toCreation mealId >> Requests.createMealEntry authorizedAccess
        , saveElement = \authorizedAccess mealId _ updateInput -> MealEntryUpdateClientInput.to mealId updateInput |> Requests.saveMealEntry authorizedAccess
        , deleteElement = Requests.deleteMealEntry
        , storeChoices = \_ -> Cmd.none
        }
