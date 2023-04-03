module Pages.MealEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Pages.MealEntries.Entries.Handler
import Pages.MealEntries.Meal.Handler
import Pages.MealEntries.Page as Page exposing (LogicMsg(..))
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess flags.mealId
    , initialFetch
        flags.authorizedAccess
        flags.mealId
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.LogicMsg
initialFetch authorizedAccess mealId =
    Cmd.batch
        [ Pages.MealEntries.Meal.Handler.initialFetch authorizedAccess mealId |> Cmd.map Page.MealMsg
        , Pages.MealEntries.Entries.Handler.initialFetch authorizedAccess mealId |> Cmd.map Page.EntriesMsg
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
                , subModelOf = Page.entriesSubModel
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
                , subModelOf = Page.mealSubModel
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.MealEntries.Meal.Handler.updateLogic
                , toMsg = Page.MealMsg
                }
                mealMsg
                model
