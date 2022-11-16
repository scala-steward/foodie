module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Recipe exposing (Recipe)
import Dict exposing (Dict)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup exposing (FoodGroup)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Pagination exposing (Pagination)
import Pages.Ingredients.RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    , recipeInfo : Maybe RecipeInfo
    , ingredientsGroup : FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput
    , complexIngredientsGroup : FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput
    , initialization : Initialization Status
    , foodsMode : FoodsMode
    , ingredientsSearchString : String
    , complexIngredientsSearchString : String
    }


type alias PlainIngredientState =
    FoodGroup.IngredientState Ingredient IngredientUpdateClientInput


type alias ComplexIngredientState =
    FoodGroup.IngredientState ComplexIngredient ComplexIngredientClientInput


type alias FoodMap =
    Dict FoodId Food


type alias ComplexFoodMap =
    Dict ComplexFoodId ComplexFood


type alias RecipeMap =
    Dict RecipeId Recipe


type alias AddFoodsMap =
    Dict FoodId IngredientCreationClientInput


type alias AddComplexFoodsMap =
    Dict ComplexFoodId ComplexIngredientClientInput


type alias PlainIngredientStateMap =
    Dict IngredientId PlainIngredientState


type alias ComplexIngredientStateMap =
    Dict ComplexIngredientId ComplexIngredientState


type FoodsMode
    = Plain
    | Complex


lenses :
    { ingredientsGroup : Lens Model (FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput)
    , complexIngredientsGroup : Lens Model (FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput)
    , recipeInfo : Lens Model (Maybe RecipeInfo)
    , initialization : Lens Model (Initialization Status)
    , foodsMode : Lens Model FoodsMode
    , ingredientsSearchString : Lens Model String
    , complexIngredientsSearchString : Lens Model String
    }
lenses =
    { ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
    , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
    , recipeInfo = Lens .recipeInfo (\b a -> { a | recipeInfo = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , foodsMode = Lens .foodsMode (\b a -> { a | foodsMode = b })
    , ingredientsSearchString = Lens .ingredientsSearchString (\b a -> { a | ingredientsSearchString = b })
    , complexIngredientsSearchString = Lens .complexIngredientsSearchString (\b a -> { a | complexIngredientsSearchString = b })
    }


type Msg
    = UpdateIngredient IngredientUpdateClientInput
    | UpdateComplexIngredient ComplexIngredientClientInput
    | SaveIngredientEdit IngredientUpdateClientInput
    | SaveComplexIngredientEdit ComplexIngredientClientInput
    | GotSaveIngredientResponse (Result Error Ingredient)
    | GotSaveComplexIngredientResponse (Result Error ComplexIngredient)
    | EnterEditIngredient IngredientId
    | EnterEditComplexIngredient ComplexIngredientId
    | ExitEditIngredientAt IngredientId
    | ExitEditComplexIngredientAt ComplexIngredientId
    | RequestDeleteIngredient IngredientId
    | ConfirmDeleteIngredient IngredientId
    | CancelDeleteIngredient IngredientId
    | RequestDeleteComplexIngredient ComplexIngredientId
    | ConfirmDeleteComplexIngredient ComplexIngredientId
    | CancelDeleteComplexIngredient ComplexIngredientId
    | GotDeleteIngredientResponse IngredientId (Result Error ())
    | GotDeleteComplexIngredientResponse ComplexIngredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List Ingredient))
    | GotFetchComplexIngredientsResponse (Result Error (List ComplexIngredient))
    | GotFetchFoodsResponse (Result Error (List Food))
    | GotFetchComplexFoodsResponse (Result Error (List ComplexFood))
    | GotFetchRecipeResponse (Result Error Recipe)
    | SelectFood Food
    | SelectComplexFood ComplexFood
    | DeselectFood FoodId
    | DeselectComplexFood ComplexFoodId
    | AddFood FoodId
    | AddComplexFood ComplexFoodId
    | GotAddFoodResponse (Result Error Ingredient)
    | GotAddComplexFoodResponse (Result Error ComplexIngredient)
    | UpdateAddFood IngredientCreationClientInput
    | UpdateAddComplexFood ComplexIngredientClientInput
    | UpdateFoods String
    | SetFoodsSearchString String
    | SetComplexFoodsSearchString String
    | SetIngredientsPagination Pagination
    | SetComplexIngredientsPagination Pagination
    | ChangeFoodsMode FoodsMode
    | SetIngredientsSearchString String
    | SetComplexIngredientsSearchString String


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
