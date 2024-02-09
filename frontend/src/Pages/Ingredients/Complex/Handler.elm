module Pages.Ingredients.Complex.Handler exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Pages.Ingredients.Complex.Page as Page
import Pages.Ingredients.Complex.Requests as Requests
import Pages.Ingredients.ComplexIngredientCreationClientInput as ComplexIngredientCreationClientInput
import Pages.Ingredients.ComplexIngredientUpdateClientInput as ComplexIngredientUpdateClientInput
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
        , idOfChoice = .recipeId
        , choiceIdOfElement = .complexFoodId
        , choiceIdOfCreation = .complexFoodId
        , toUpdate = ComplexIngredientUpdateClientInput.from
        , toCreation = ComplexIngredientCreationClientInput.from
        , createElement =
            \authorizedAccess recipeId creation ->
                ComplexIngredientCreationClientInput.to creation
                    |> Requests.createComplexIngredient authorizedAccess recipeId creation.complexFoodId
        , saveElement = \authorizedAccess recipeId complexFoodId updateInput -> ComplexIngredientUpdateClientInput.to updateInput |> Requests.saveComplexIngredient authorizedAccess recipeId complexFoodId
        , deleteElement = Requests.deleteComplexIngredient
        , storeChoices = \_ -> Cmd.none
        }
