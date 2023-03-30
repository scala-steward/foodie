module Pages.MealEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.MealEntries.Meal.Page
import Pages.MealEntries.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Pagination as Pagination exposing (Pagination)
import Pages.Meals.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Util.DictList as DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , meal : Pages.Util.Parent.Page.Main Meal MealUpdateClientInput
    , mealEntries : MealEntryStateMap
    , recipes : RecipeMap
    , recipesSearchString : String
    , entriesSearchString : String
    , mealEntriesToAdd : AddMealEntriesMap
    , pagination : Pagination
    }


type alias Initial =
    { jwt : JWT
    , meal : Pages.Util.Parent.Page.Initial Meal
    , mealEntries : Maybe MealEntryStateMap
    , recipes : Maybe RecipeMap
    }


mealSubModel : Model -> Pages.MealEntries.Meal.Page.Model
mealSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.meal
        , mainLens = lenses.main.meal
        }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , meal = Pages.Util.Parent.Page.initialWith authorizedAccess.jwt
    , mealEntries = Nothing
    , recipes = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.meal
        |> Pages.Util.Parent.Page.initialToMain
        |> Maybe.andThen
            (\meal ->
                Maybe.map2
                    (\mealEntries recipes ->
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
                    i.mealEntries
                    i.recipes
            )


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
        { meal : Lens Initial (Pages.Util.Parent.Page.Initial Meal)
        , mealEntries : Lens Initial (Maybe MealEntryStateMap)
        , recipes : Lens Initial (Maybe RecipeMap)
        }
    , main :
        { meal : Lens Main (Pages.Util.Parent.Page.Main Meal MealUpdateClientInput)
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


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
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
    | SelectRecipe RecipeId
    | DeselectRecipe RecipeId
    | AddRecipe RecipeId
    | GotAddMealEntryResponse (Result Error MealEntry)
    | UpdateAddRecipe MealEntryCreationClientInput
    | SetRecipesSearchString String
    | SetEntriesSearchString String
    | SetPagination Pagination
    | MealMsg Pages.MealEntries.Meal.Page.LogicMsg
