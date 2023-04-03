module Pages.ComplexFoods.Foods.Handler exposing (..)

import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput
import Pages.ComplexFoods.Foods.Page as Page
import Pages.ComplexFoods.Foods.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler


initialFetch : AuthorizedAccess -> Cmd Page.LogicMsg
initialFetch authorizedAccess =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchComplexFoods authorizedAccess
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .recipeId
        , idOfUpdate = .recipeId
        , idOfChoice = .id
        , choiceIdOfElement = .recipeId
        , choiceIdOfCreation = .recipeId
        , toUpdate = ComplexFoodClientInput.from
        , toCreation = \recipe _ -> ComplexFoodClientInput.withSuggestion recipe
        , createElement = \authorizedAccess _ -> ComplexFoodClientInput.to >> Requests.createComplexFood authorizedAccess
        , saveElement = \authorizedAccess _ -> ComplexFoodClientInput.to >> Requests.updateComplexFood authorizedAccess
        , deleteElement = \authorizedAccess _ -> Requests.deleteComplexFood authorizedAccess
        , storeChoices = Cmd.none |> always
        }
