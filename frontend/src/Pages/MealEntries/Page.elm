module Pages.MealEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Monocle.Lens exposing (Lens)
import Pages.MealEntries.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Pagination as Pagination exposing (Pagination)
import Pages.Meals.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList as DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , meal : Editing Meal MealUpdateClientInput
    , mealEntries : MealEntryStateMap
    , recipes : RecipeMap
    , recipesSearchString : String
    , entriesSearchString : String
    , mealEntriesToAdd : AddMealEntriesMap
    , pagination : Pagination
    }


type alias Initial =
    { jwt : JWT
    , meal : Maybe (Editing Meal MealUpdateClientInput)
    , mealEntries : Maybe MealEntryStateMap
    , recipes : Maybe RecipeMap
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , meal = Nothing
    , mealEntries = Nothing
    , recipes = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map3
        (\meal mealEntries recipes ->
            { jwt = i.jwt
            , meal = meal
            , mealEntries = mealEntries
            , recipes = recipes
            , recipesSearchString = ""
            , entriesSearchString = ""
            , mealEntriesToAdd = DictList.empty
            , pagination = Pagination.initial
            }
        )
        i.meal
        i.mealEntries
        i.recipes


type alias MealEntryState =
    Editing MealEntry MealEntryUpdateClientInput


type alias RecipeMap =
    DictList RecipeId Recipe


type alias AddMealEntriesMap =
    DictList RecipeId MealEntryCreationClientInput


type alias MealEntryStateMap =
    DictList MealEntryId MealEntryState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , mealId : MealId
    }


lenses :
    { initial :
        { meal : Lens Initial (Maybe (Editing Meal MealUpdateClientInput))
        , mealEntries : Lens Initial (Maybe MealEntryStateMap)
        , recipes : Lens Initial (Maybe RecipeMap)
        }
    , main :
        { meal : Lens Main (Editing Meal MealUpdateClientInput)
        , mealEntries : Lens Main MealEntryStateMap
        , mealEntriesToAdd : Lens Main AddMealEntriesMap
        , recipes : Lens Main RecipeMap
        , recipesSearchString : Lens Main String
        , entriesSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial =
        { meal = Lens .meal (\b a -> { a | meal = b })
        , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
        , recipes = Lens .recipes (\b a -> { a | recipes = b })
        }
    , main =
        { meal = Lens .meal (\b a -> { a | meal = b })
        , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
        , mealEntriesToAdd = Lens .mealEntriesToAdd (\b a -> { a | mealEntriesToAdd = b })
        , recipes = Lens .recipes (\b a -> { a | recipes = b })
        , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
        , entriesSearchString = Lens .entriesSearchString (\b a -> { a | entriesSearchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


descriptionOrEmpty : RecipeMap -> RecipeId -> String
descriptionOrEmpty recipeMap =
    flip DictList.get recipeMap >> Maybe.andThen .description >> Maybe.withDefault ""


type Msg
    = UpdateMealEntry MealEntryUpdateClientInput
    | SaveMealEntryEdit MealEntryUpdateClientInput
    | GotSaveMealEntryResponse (Result Error MealEntry)
    | EnterEditMealEntry MealEntryId
    | ExitEditMealEntryAt MealEntryId
    | RequestDeleteMealEntry MealEntryId
    | ConfirmDeleteMealEntry MealEntryId
    | CancelDeleteMealEntry MealEntryId
    | GotDeleteMealEntryResponse MealEntryId (Result Error ())
    | GotFetchMealEntriesResponse (Result Error (List MealEntry))
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | GotFetchMealResponse (Result Error Meal)
    | SelectRecipe RecipeId
    | DeselectRecipe RecipeId
    | AddRecipe RecipeId
    | GotAddMealEntryResponse (Result Error MealEntry)
    | UpdateAddRecipe MealEntryCreationClientInput
    | SetRecipesSearchString String
    | SetEntriesSearchString String
    | SetPagination Pagination
    | UpdateMeal MealUpdateClientInput
    | SaveMealEdit
    | GotSaveMealResponse (Result Error Meal)
    | EnterEditMeal
    | ExitEditMeal
    | RequestDeleteMeal
    | ConfirmDeleteMeal
    | CancelDeleteMeal
    | GotDeleteMealResponse (Result Error ())
