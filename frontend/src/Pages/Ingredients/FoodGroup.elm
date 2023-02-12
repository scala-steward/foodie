module Pages.Ingredients.FoodGroup exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Util.DictList as DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias Main ingredientId ingredient update foodId food creation =
    { ingredients : DictList ingredientId (IngredientState ingredient update)
    , foods : DictList foodId food
    , foodsToAdd : DictList foodId creation
    , pagination : Pagination
    , foodsSearchString : String
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
            , foods = foods
            , foodsToAdd = DictList.empty
            , pagination = Pagination.initial
            , foodsSearchString = ""
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
        , foods : Lens (Main ingredientId ingredient update foodId food creation) (DictList foodId food)
        , foodsToAdd : Lens (Main ingredientId ingredient update foodId food creation) (DictList foodId creation)
        , pagination : Lens (Main ingredientId ingredient update foodId food creation) Pagination
        , foodsSearchString : Lens (Main ingredientId ingredient update foodId food creation) String
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
        , foodsToAdd = Lens .foodsToAdd (\b a -> { a | foodsToAdd = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
        }
    }
