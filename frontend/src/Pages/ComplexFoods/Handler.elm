module Pages.ComplexFoods.Handler exposing (init, update)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.ComplexFoods.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler
import Pages.View.Tristate as Tristate


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags.authorizedAccess
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> Cmd Page.LogicMsg
initialFetch authorizedAccess =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchComplexFoods authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .recipeId
        , idOfUpdate = .recipeId
        , idOfChoice = .id
        , choiceIdOfElement = .recipeId
        , choiceIdOfCreation = .recipeId
        , toUpdate = ComplexFoodClientInput.from
        , toCreation = \recipe _ -> ComplexFoodClientInput.default recipe.id
        , createElement = \authorizedAccess _ -> ComplexFoodClientInput.to >> Requests.createComplexFood authorizedAccess
        , saveElement = \authorizedAccess _ -> ComplexFoodClientInput.to >> Requests.updateComplexFood authorizedAccess
        , deleteElement = \authorizedAccess _ -> Requests.deleteComplexFood authorizedAccess
        , storeChoices = Cmd.none |> always
        }
