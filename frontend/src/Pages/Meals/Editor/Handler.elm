module Pages.Meals.Editor.Handler exposing (init, update)

import Addresses.Frontend
import Api.Types.Meal exposing (Meal)
import Maybe.Extra
import Monocle.Lens
import Pages.Meals.Editor.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Editor.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Editor.Page as Page
import Pages.Meals.Editor.Requests as Requests
import Pages.Util.DateUtil as DateUtil
import Pages.Util.ParentEditor.Handler
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Pages.Util.SimpleDateInput as SimpleDateInput
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Result.Extra


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { parentEditor =
            { parents = Nothing
            , jwt = flags.authorizedAccess.jwt
            }
      , profile = Nothing
      , profileId = flags.profileId |> Debug.log "profileId"
      }
        |> Tristate.createInitial flags.authorizedAccess.configuration
    , Cmd.batch
        [ Pages.Util.Requests.fetchProfileWith Page.GotFetchProfileResponse flags.authorizedAccess flags.profileId
        , Requests.fetchMeals flags.authorizedAccess flags.profileId
        ]
        |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Tristate.Model Page.Main Page.Initial -> ( Tristate.Model Page.Main Page.Initial, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.ParentEditorMsg parentEditorMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.parentEditor
                , mainSubModelLens = Page.lenses.main.parentEditor
                , fromInitToMain = Page.initialToMain
                , updateSubModel =
                    \subModelMsg subModel ->
                        model
                            |> Page.profileId
                            |> Maybe.Extra.unwrap ( subModel, Cmd.none )
                                (\profileId ->
                                    Pages.Util.ParentEditor.Handler.updateLogic
                                        { idOfParent = .id
                                        , toUpdate = MealUpdateClientInput.from
                                        , navigateToAddress = \mealId -> Addresses.Frontend.mealEntryEditor.address ( profileId, mealId )
                                        , updateCreationTimestamp = DateUtil.fromPosix >> SimpleDateInput.from >> MealCreationClientInput.lenses.date.set
                                        , create = \authorizedAccess -> MealCreationClientInput.toCreation >> Maybe.Extra.unwrap Cmd.none (Requests.createMeal authorizedAccess profileId)
                                        , save = \authorizedAccess mealId -> MealUpdateClientInput.to >> Maybe.Extra.unwrap Cmd.none (Requests.saveMeal authorizedAccess profileId mealId)
                                        , delete = \authorizedAccess -> Requests.deleteMeal authorizedAccess profileId
                                        , duplicate = \authorizedAccess -> Pages.Util.Requests.duplicateMealWith Pages.Util.ParentEditor.Page.GotDuplicateResponse authorizedAccess profileId
                                        , attemptInitialToMainAfterFetchResponse = False
                                        }
                                        subModelMsg
                                        subModel
                                )
                , toMsg = Page.ParentEditorMsg
                }
                parentEditorMsg
                model

        Page.GotFetchProfileResponse result ->
            ( result
                |> Result.Extra.unpack
                    (Tristate.toError model)
                    (\profile ->
                        Tristate.mapInitial
                            (Page.lenses.initial.profile.set (Just profile))
                            model
                            |> Tristate.fromInitToMain Page.initialToMain
                    )
            , Cmd.none
            )
