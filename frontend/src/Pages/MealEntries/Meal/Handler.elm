module Pages.MealEntries.Meal.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (MealId, ProfileId)
import Maybe.Extra
import Pages.MealEntries.Meal.Page as Page
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Handler
import Pages.Util.Parent.Page
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Result.Extra


initialFetch : AuthorizedAccess -> ProfileId -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess profileId mealId =
    Cmd.batch
        [ Pages.Util.Requests.fetchMealWith Pages.Util.Parent.Page.GotFetchResponse authorizedAccess profileId mealId
            |> Cmd.map Page.ParentMsg
        , Pages.Util.Requests.fetchProfileWith Page.GotFetchProfileResponse authorizedAccess profileId
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.ParentMsg parentMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.parent
                , mainSubModelLens = Page.lenses.main.parent
                , fromInitToMain = Page.initialToMain
                , updateSubModel =
                    \subModelMsg subModel ->
                        model
                            |> Page.profileId
                            |> Maybe.Extra.unwrap ( subModel, Cmd.none )
                                (\profileId ->
                                    Pages.Util.Parent.Handler.updateLogic
                                        { toUpdate = MealUpdateClientInput.from
                                        , idOf = .id
                                        , save =
                                            \authorizedAccess mealId ->
                                                MealUpdateClientInput.to
                                                    >> Maybe.map
                                                        (Pages.Util.Requests.saveMealWith
                                                            Pages.Util.Parent.Page.GotSaveEditResponse
                                                            authorizedAccess
                                                            profileId
                                                            mealId
                                                        )
                                        , delete = \authorizedAccess -> Pages.Util.Requests.deleteMealWith Pages.Util.Parent.Page.GotDeleteResponse authorizedAccess profileId
                                        , duplicate = \authorizedAccess -> Pages.Util.Requests.duplicateMealWith Pages.Util.Parent.Page.GotDuplicateResponse authorizedAccess profileId
                                        , navigateAfterDeletionAddress = \_ -> Addresses.Frontend.meals.address profileId
                                        , navigateAfterDuplicationAddress = \mealId -> Addresses.Frontend.mealEntryEditor.address ( profileId, mealId )
                                        }
                                        subModelMsg
                                        subModel
                                )
                , toMsg = Page.ParentMsg
                }
                parentMsg
                model

        Page.GotFetchProfileResponse result ->
            ( result
                |> Result.Extra.unpack
                    (Tristate.toError model)
                    (\profile -> Tristate.mapInitial (Page.lenses.initial.profile.set (Just profile)) model)
            , Cmd.none
            )
