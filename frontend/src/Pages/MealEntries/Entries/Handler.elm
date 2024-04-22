module Pages.MealEntries.Entries.Handler exposing (..)

import Api.Auxiliary exposing (MealId, ProfileId)
import Pages.MealEntries.Entries.Page as Page
import Pages.MealEntries.Entries.Requests as Requests
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler


initialFetch : AuthorizedAccess -> ProfileId -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess profileId mealId =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchMealEntries authorizedAccess profileId mealId
        ]


updateLogic : ProfileId -> Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic profileId =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .id
        , idOfChoice = .id
        , choiceIdOfElement = .recipeId
        , choiceIdOfCreation = .recipeId
        , toUpdate = MealEntryUpdateClientInput.from
        , toCreation = \recipe -> MealEntryCreationClientInput.default recipe.id
        , createElement = \authorizedAccess mealId creationInput -> MealEntryCreationClientInput.toCreation creationInput |> Requests.createMealEntry authorizedAccess profileId mealId
        , saveElement = \authorizedAccess mealId mealEntryId updateInput -> MealEntryUpdateClientInput.to updateInput |> Requests.saveMealEntry authorizedAccess profileId mealId mealEntryId
        , deleteElement = \authorizedAccess -> Requests.deleteMealEntry authorizedAccess profileId
        , storeChoices = \_ -> Cmd.none
        }
