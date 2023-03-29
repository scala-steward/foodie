module Pages.Ingredients.Complex.Handler exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Pages.Ingredients.Complex.Page as Page
import Pages.Ingredients.Complex.Requests as Requests
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchComplexIngredients authorizedAccess recipeId
        , Requests.fetchComplexFoods authorizedAccess
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .complexFoodId
        , idOfUpdate = .complexFoodId
        , idOfChoice = .recipeId
        , choiceIdOfElement = .complexFoodId
        , choiceIdOfCreation = .complexFoodId
        , toUpdate = ComplexIngredientClientInput.from
        , toCreation = \food _ -> ComplexIngredientClientInput.fromFood food
        , createElement =
            \authorizedAccess recipeId ->
                ComplexIngredientClientInput.to
                    >> Requests.createComplexIngredient authorizedAccess recipeId
        , saveElement = \authorizedAccess recipeId updateInput -> ComplexIngredientClientInput.to updateInput |> Requests.saveComplexIngredient authorizedAccess recipeId
        , deleteElement = Requests.deleteComplexIngredient
        , storeChoices = \_ -> Cmd.none
        }
