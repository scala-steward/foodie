module Pages.Ingredients.Complex.Handler exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Pages.Ingredients.Complex.Page as Page
import Pages.Ingredients.Complex.Requests as Requests
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput
import Pages.Ingredients.FoodGroupHandler as FoodGroupHandler
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchComplexIngredients authorizedAccess recipeId
        , Requests.fetchComplexFoods authorizedAccess
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    FoodGroupHandler.updateLogic
        { idOfIngredient = .complexFoodId
        , idOfUpdate = .complexFoodId
        , idOfFood = .recipeId
        , foodIdOfIngredient = .complexFoodId
        , foodIdOfCreation = .complexFoodId
        , toUpdate = ComplexIngredientClientInput.from
        , toCreation = \food _ -> ComplexIngredientClientInput.fromFood food
        , createIngredient =
            \authorizedAccess recipeId ->
                ComplexIngredientClientInput.to
                    >> Requests.createComplexIngredient authorizedAccess recipeId
        , saveIngredient = \authorizedAccess recipeId updateInput -> ComplexIngredientClientInput.to updateInput |> Requests.saveComplexIngredient authorizedAccess recipeId
        , deleteIngredient = Requests.deleteComplexIngredient
        , storeFoods = \_ -> Cmd.none
        }
