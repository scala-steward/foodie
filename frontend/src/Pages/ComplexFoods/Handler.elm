module Pages.ComplexFoods.Handler exposing (init, update)

import Pages.ComplexFoods.Foods.Handler
import Pages.ComplexFoods.Page as Page
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , Pages.ComplexFoods.Foods.Handler.initialFetch flags.authorizedAccess
        |> Cmd.map (Page.FoodsMsg >> Tristate.Logic)
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.FoodsMsg foodsMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.foods
                , mainSubModelLens = Page.lenses.main.foods
                , subModelOf = Page.foodsSubModel
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.ComplexFoods.Foods.Handler.updateLogic
                , toMsg = Page.FoodsMsg
                }
                foodsMsg
                model
