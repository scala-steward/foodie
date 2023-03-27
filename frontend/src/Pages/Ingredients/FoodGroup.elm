module Pages.Ingredients.FoodGroup exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Pages.View.Tristate as Tristate
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model ingredientId ingredient update foodId food creation =
    Tristate.Model (Main ingredientId ingredient update foodId food creation) (Initial ingredientId ingredient update foodId food)


type alias Main ingredientId ingredient update foodId food creation =
    { ingredients : DictList ingredientId (IngredientState ingredient update)
    , foods : DictList foodId (Editing food creation)
    , pagination : Pagination
    , foodsSearchString : String
    , ingredientsSearchString : String
    }


type alias Initial ingredientId ingredient update foodId food =
    { ingredients : Maybe (DictList ingredientId (IngredientState ingredient update))
    , foods : Maybe (DictList foodId food)
    }


initial : Initial ingredientId ingredient update foodId food
initial =
    { ingredients = Nothing
    , foods = Nothing
    }


initialToMain : Initial ingredientId ingredient update foodId food -> Maybe (Main ingredientId ingredient update foodId food creation)
initialToMain i =
    Maybe.map2
        (\ingredients foods ->
            { ingredients = ingredients
            , foods = foods |> DictList.map Editing.asView
            , pagination = Pagination.initial
            , foodsSearchString = ""
            , ingredientsSearchString = ""
            }
        )
        i.ingredients
        i.foods


type alias IngredientState ingredient update =
    Editing ingredient update


lenses :
    { initial :
        { ingredients : Lens (Initial ingredientId ingredient update foodId food) (Maybe (DictList ingredientId (IngredientState ingredient update)))
        , foods : Lens (Initial ingredientId ingredient update foodId food) (Maybe (DictList foodId food))
        }
    , main :
        { ingredients : Lens (Main ingredientId ingredient update foodId food creation) (DictList ingredientId (IngredientState ingredient update))
        , foods : Lens (Main ingredientId ingredient update foodId food creation) (DictList foodId (Editing food creation))
        , pagination : Lens (Main ingredientId ingredient update foodId food creation) Pagination
        , foodsSearchString : Lens (Main ingredientId ingredient update foodId food creation) String
        , ingredientsSearchString : Lens (Main ingredientId ingredient update foodId food creation) String
        }
    }
lenses =
    { initial =
        { ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
        , foods = Lens .foods (\b a -> { a | foods = b })
        }
    , main =
        { ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
        , foods = Lens .foods (\b a -> { a | foods = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
        , ingredientsSearchString = Lens .ingredientsSearchString (\b a -> { a | ingredientsSearchString = b })
        }
    }


type LogicMsg ingredientId ingredient update foodId food creation
    = EditIngredient update
    | SaveIngredientEdit update
    | GotSaveIngredientResponse (Result Error ingredient)
    | ToggleControls ingredientId
    | EnterEditIngredient ingredientId
    | ExitEditIngredient ingredientId
    | RequestDeleteIngredient ingredientId
    | ConfirmDeleteIngredient ingredientId
    | CancelDeleteIngredient ingredientId
    | GotDeleteIngredientResponse ingredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List ingredient))
    | GotFetchFoodsResponse (Result Error (List food))
    | SelectFood food
    | DeselectFood foodId
    | Create foodId
    | GotCreateResponse (Result Error ingredient)
    | UpdateCreation creation
    | SetIngredientsPagination Pagination
    | SetIngredientsSearchString String
    | SetFoodsSearchString String
