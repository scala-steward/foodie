module Pages.Ingredients.Plain.Handler exposing (initialFetch, updateLogic)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food, encoderFood)
import Api.Types.Ingredient exposing (Ingredient)
import Json.Encode as Encode
import Maybe.Extra
import Pages.Util.Choice.ChoiceGroupHandler as ChoiceGroupHandler
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Plain.Page as Page
import Pages.Ingredients.Plain.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Ports exposing (doFetchFoods, storeFoods)


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchIngredients authorizedAccess recipeId
        , doFetchFoods ()
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    ChoiceGroupHandler.updateLogic
        { idOfElement = .id
        , idOfUpdate = .ingredientId
        , idOfChoice = .id
        , choiceIdOfElement = .foodId
        , choiceIdOfCreation = .foodId
        , toUpdate = IngredientUpdateClientInput.from
        , toCreation = \food recipeId -> IngredientCreationClientInput.default recipeId food.id (food.measures |> List.head |> Maybe.Extra.unwrap 0 .id)
        , createElement = \authorizedAccess _ -> IngredientCreationClientInput.toCreation >> Requests.createIngredient authorizedAccess
        , saveElement = \authorizedAccess _ updateInput -> IngredientUpdateClientInput.to updateInput |> Requests.saveIngredient authorizedAccess
        , deleteElement = \authorizedAccess _ -> Requests.deleteIngredient authorizedAccess
        , storeChoices =
            Encode.list encoderFood
                >> Encode.encode 0
                >> storeFoods
        }
