module Pages.ComplexFoods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, JWT, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList as DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipes : RecipeMap
    , complexFoods : ComplexFoodStateMap
    , complexFoodsToCreate : CreateComplexFoodsMap
    , recipesSearchString : String
    , complexFoodsSearchString : String
    , pagination : Pagination
    }


type alias Initial =
    { recipes : Maybe RecipeMap
    , complexFoods : Maybe ComplexFoodStateMap
    , jwt : JWT
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { recipes = Nothing
    , complexFoods = Nothing
    , jwt = authorizedAccess.jwt
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map2
        (\recipes complexFoods ->
            { jwt = i.jwt
            , recipes = recipes
            , complexFoods = complexFoods
            , complexFoodsToCreate = DictList.empty
            , recipesSearchString = ""
            , complexFoodsSearchString = ""
            , pagination = Pagination.initial
            }
        )
        i.recipes
        i.complexFoods


type alias ComplexFoodState =
    Editing ComplexFood ComplexFoodClientInput


type alias ComplexFoodStateMap =
    DictList ComplexFoodId ComplexFoodState


type alias CreateComplexFoodsMap =
    DictList ComplexFoodId ComplexFoodClientInput


type alias RecipeMap =
    DictList RecipeId Recipe


lenses :
    { initial :
        { recipes : Lens Initial (Maybe RecipeMap)
        , complexFoods : Lens Initial (Maybe ComplexFoodStateMap)
        }
    , main :
        { recipes : Lens Main RecipeMap
        , complexFoods : Lens Main ComplexFoodStateMap
        , complexFoodsToCreate : Lens Main CreateComplexFoodsMap
        , recipesSearchString : Lens Main String
        , complexFoodsSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial =
        { recipes = Lens .recipes (\b a -> { a | recipes = b })
        , complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
        }
    , main =
        { recipes = Lens .recipes (\b a -> { a | recipes = b })
        , complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
        , complexFoodsToCreate = Lens .complexFoodsToCreate (\b a -> { a | complexFoodsToCreate = b })
        , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
        , complexFoodsSearchString = Lens .complexFoodsSearchString (\b a -> { a | complexFoodsSearchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
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
