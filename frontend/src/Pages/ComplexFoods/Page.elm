module Pages.ComplexFoods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Pagination exposing (Pagination)
import Pages.ComplexFoods.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipes : RecipeMap
    , complexFoods : ComplexFoodStateMap
    , complexFoodsToCreate : CreateComplexFoodsMap
    , recipesSearchString : String
    , complexFoodsSearchString : String
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias ComplexFoodState =
    Editing ComplexFood ComplexFoodClientInput


type alias ComplexFoodStateMap =
    DictList ComplexFoodId ComplexFoodState


type alias CreateComplexFoodsMap =
    DictList ComplexFoodId ComplexFoodClientInput


type alias RecipeMap =
    DictList RecipeId Recipe


lenses :
    { recipes : Lens Model RecipeMap
    , complexFoods : Lens Model ComplexFoodStateMap
    , complexFoodsToCreate : Lens Model CreateComplexFoodsMap
    , recipesSearchString : Lens Model String
    , complexFoodsSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { recipes = Lens .recipes (\b a -> { a | recipes = b })
    , complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    , complexFoodsToCreate = Lens .complexFoodsToCreate (\b a -> { a | complexFoodsToCreate = b })
    , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
    , complexFoodsSearchString = Lens .complexFoodsSearchString (\b a -> { a | complexFoodsSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = UpdateComplexFoodCreation ComplexFoodClientInput
    | CreateComplexFood RecipeId
    | GotCreateComplexFoodResponse (Result Error ComplexFood)
    | UpdateComplexFood ComplexFoodClientInput
    | SaveComplexFoodEdit ComplexFoodClientInput
    | GotSaveComplexFoodResponse (Result Error ComplexFood)
    | EnterEditComplexFood ComplexFoodId
    | ExitEditComplexFood ComplexFoodId
    | RequestDeleteComplexFood ComplexFoodId
    | ConfirmDeleteComplexFood ComplexFoodId
    | CancelDeleteComplexFood ComplexFoodId
    | GotDeleteComplexFoodResponse ComplexFoodId (Result Error ())
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | GotFetchComplexFoodsResponse (Result Error (List ComplexFood))
    | SelectRecipe Recipe
    | DeselectRecipe RecipeId
    | SetRecipesSearchString String
    | SetComplexFoodsSearchString String
    | SetPagination Pagination
