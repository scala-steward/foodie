module Pages.MealEntries.Entries.Handler exposing (..)

import Api.Auxiliary exposing (MealId, ProfileId)
import Maybe.Extra
import Pages.MealEntries.Entries.Page as Page
import Pages.MealEntries.Entries.Requests as Requests
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Result.Extra


initialFetch : AuthorizedAccess -> ProfileId -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess profileId mealId =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchMealEntries authorizedAccess profileId mealId
        , Pages.Util.Requests.fetchProfileWith Page.GotFetchProfileResponse authorizedAccess profileId
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.ChoiceMsg choiceMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.choices
                , mainSubModelLens = Page.lenses.main.choices
                , fromInitToMain = Page.initialToMain
                , updateSubModel =
                    \subModelMsg subModel ->
                        model
                            |> Page.profileId
                            |> Maybe.Extra.unwrap ( subModel, Cmd.none )
                                (\profileId ->
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
                                        subModelMsg
                                        subModel
                                )
                , toMsg = Page.ChoiceMsg
                }
                choiceMsg
                model

        Page.GotFetchProfileResponse result ->
            ( result
                |> Result.Extra.unpack
                    (Tristate.toError model)
                    (\profile -> Tristate.mapInitial (Page.lenses.initial.profile.set (Just profile)) model)
            , Cmd.none
            )
