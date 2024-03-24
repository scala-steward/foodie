module Pages.MealEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, ProfileId, RecipeId)
import Monocle.Compose as Compose
import Pages.MealEntries.Entries.Handler
import Pages.MealEntries.Entries.Page
import Pages.MealEntries.Meal.Handler
import Pages.MealEntries.Meal.Page
import Pages.MealEntries.Page as Page exposing (LogicMsg(..))
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Result.Extra


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess flags.mealId
    , initialFetch
        flags.authorizedAccess
        flags.profileId
        flags.mealId
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> ProfileId -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess profileId mealId =
    Cmd.batch
        [ Pages.MealEntries.Meal.Handler.initialFetch authorizedAccess profileId mealId |> Cmd.map Page.MealMsg
        , Pages.MealEntries.Entries.Handler.initialFetch authorizedAccess profileId mealId |> Cmd.map Page.EntriesMsg
        , Pages.Util.Requests.fetchProfileWith Page.GotFetchProfileResponse authorizedAccess profileId
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.EntriesMsg entriesMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.entries
                , mainSubModelLens = Page.lenses.main.entries
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.MealEntries.Entries.Handler.updateLogic
                , toMsg = Page.EntriesMsg
                }
                entriesMsg
                model

        Page.MealMsg mealMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.meal
                , mainSubModelLens = Page.lenses.main.meal
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.MealEntries.Meal.Handler.updateLogic
                , toMsg = Page.MealMsg
                }
                mealMsg
                model

        Page.GotFetchProfileResponse result ->
            ( result
                |> Result.Extra.unpack
                    (Tristate.toError model)
                    (\profile ->
                        model
                            |> Tristate.mapInitial
                                ((Page.lenses.initial.meal |> Compose.lensWithLens Pages.MealEntries.Meal.Page.lenses.initial.profile).set (Just profile)
                                    >> (Page.lenses.initial.entries |> Compose.lensWithLens Pages.MealEntries.Entries.Page.lenses.initial.profile).set (Just profile)
                                )
                    )
            , Cmd.none
            )
