module Pages.Recipes.Page exposing (..)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Pagination as Pagination exposing (Pagination)
import Pages.Recipes.RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipes : RecipeStateMap
    , recipeToAdd : Maybe RecipeCreationClientInput
    , searchString : String
    , pagination : Pagination
    }


type alias Initial =
    { recipes : Maybe RecipeStateMap
    , jwt : JWT
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { recipes = Nothing
    , jwt = authorizedAccess.jwt
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.recipes
        |> Maybe.map
            (\recipes ->
                { jwt = i.jwt
                , recipes = recipes
                , recipeToAdd = Nothing
                , searchString = ""
                , pagination = Pagination.initial
                }
            )


type alias RecipeState =
    Editing Recipe RecipeUpdateClientInput


type alias RecipeStateMap =
    DictList RecipeId RecipeState


lenses :
    { initial : { recipes : Lens Initial (Maybe RecipeStateMap) }
    , main :
        { recipes : Lens Main RecipeStateMap
        , recipeToAdd : Lens Main (Maybe RecipeCreationClientInput)
        , searchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial =
        { recipes = Lens .recipes (\b a -> { a | recipes = b })
        }
    , main =
        { recipes = Lens .recipes (\b a -> { a | recipes = b })
        , recipeToAdd = Lens .recipeToAdd (\b a -> { a | recipeToAdd = b })
        , searchString = Lens .searchString (\b a -> { a | searchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = UpdateRecipeCreation (Maybe RecipeCreationClientInput)
    | CreateRecipe
    | GotCreateRecipeResponse (Result Error Recipe)
    | UpdateRecipe RecipeUpdateClientInput
    | SaveRecipeEdit RecipeId
    | GotSaveRecipeResponse (Result Error Recipe)
    | EnterEditRecipe RecipeId
    | ExitEditRecipeAt RecipeId
    | RequestDeleteRecipe RecipeId
    | ConfirmDeleteRecipe RecipeId
    | CancelDeleteRecipe RecipeId
    | GotDeleteRecipeResponse RecipeId (Result Error ())
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | SetPagination Pagination
    | SetSearchString String
