module Pages.MealEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Monocle.Lens exposing (Lens)
import Pages.MealEntries.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.MealInfo exposing (MealInfo)
import Pages.MealEntries.Pagination exposing (Pagination)
import Pages.MealEntries.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , mealId : MealId
    , mealInfo : Maybe MealInfo
    , mealEntries : MealEntryStateMap
    , recipes : RecipeMap
    , recipesSearchString : String
    , entriesSearchString : String
    , mealEntriesToAdd : AddMealEntriesMap
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias MealEntryState =
    Editing MealEntry MealEntryUpdateClientInput


type alias RecipeMap =
    Dict RecipeId Recipe


type alias AddMealEntriesMap =
    Dict RecipeId MealEntryCreationClientInput


type alias MealEntryStateMap =
    Dict MealEntryId MealEntryState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , mealId : MealId
    }


lenses :
    { mealInfo : Lens Model (Maybe MealInfo)
    , mealEntries : Lens Model MealEntryStateMap
    , mealEntriesToAdd : Lens Model AddMealEntriesMap
    , recipes : Lens Model RecipeMap
    , recipesSearchString : Lens Model String
    , entriesSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { mealInfo = Lens .mealInfo (\b a -> { a | mealInfo = b })
    , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , mealEntriesToAdd = Lens .mealEntriesToAdd (\b a -> { a | mealEntriesToAdd = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
    , entriesSearchString = Lens .entriesSearchString (\b a -> { a | entriesSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


descriptionOrEmpty : RecipeMap -> RecipeId -> String
descriptionOrEmpty recipeMap =
    flip Dict.get recipeMap >> Maybe.andThen .description >> Maybe.withDefault ""


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