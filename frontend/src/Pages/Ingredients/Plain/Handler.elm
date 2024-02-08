module Pages.Ingredients.Plain.Handler exposing (initialFetch, updateLogic)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food, encoderFood)
import Api.Types.Ingredient exposing (Ingredient)
import Json.Encode as Encode
import Maybe.Extra
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Plain.Page as Page
import Pages.Ingredients.Plain.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler
import Ports


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchIngredients authorizedAccess recipeId
        , Ports.doFetchFoods ()
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .id
        , idOfUpdate = .ingredientId
        , idOfChoice = .id
        , choiceIdOfElement = .foodId
        , choiceIdOfCreation = .foodId
        , toUpdate = IngredientUpdateClientInput.from
        , toCreation = \food -> IngredientCreationClientInput.default food.id (food.measures |> List.head |> Maybe.Extra.unwrap 0 .id)
        , createElement = \authorizedAccess recipeId -> IngredientCreationClientInput.toCreation >> Requests.createIngredient authorizedAccess recipeId
        , saveElement = \authorizedAccess recipeId ingredientId updateInput -> IngredientUpdateClientInput.to updateInput |> Requests.saveIngredient authorizedAccess recipeId ingredientId
        , deleteElement = Requests.deleteIngredient
        , storeChoices =
            Encode.list encoderFood
                >> Encode.encode 0
                >> Ports.storeFoods
        }
