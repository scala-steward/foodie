module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup exposing (FoodGroup)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Pagination exposing (Pagination)
import Pages.Ingredients.Status exposing (Status)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipe : Editing Recipe RecipeUpdateClientInput
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
    DictList FoodId Food


type alias ComplexFoodMap =
    DictList ComplexFoodId ComplexFood


type alias RecipeMap =
    DictList RecipeId Recipe


type alias AddFoodsMap =
    DictList FoodId IngredientCreationClientInput


type alias AddComplexFoodsMap =
    DictList ComplexFoodId ComplexIngredientClientInput


type alias PlainIngredientStateMap =
    DictList IngredientId PlainIngredientState


type alias ComplexIngredientStateMap =
    DictList ComplexIngredientId ComplexIngredientState


type FoodsMode
    = Plain
    | Complex


lenses :
    { ingredientsGroup : Lens Model (FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput)
    , complexIngredientsGroup : Lens Model (FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput)
    , recipe : Lens Model (Editing Recipe RecipeUpdateClientInput)
    , initialization : Lens Model (Initialization Status)
    , foodsMode : Lens Model FoodsMode
    , ingredientsSearchString : Lens Model String
    , complexIngredientsSearchString : Lens Model String
    }
lenses =
    { ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
    , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
    , recipe = Lens .recipe (\b a -> { a | recipe = b })
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
    | UpdateRecipe RecipeUpdateClientInput
    | SaveRecipeEdit
    | GotSaveRecipeResponse (Result Error Recipe)
    | EnterEditRecipe
    | ExitEditRecipe
    | RequestDeleteRecipe
    | ConfirmDeleteRecipe
    | CancelDeleteRecipe
    | GotDeleteRecipeResponse (Result Error ())


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
