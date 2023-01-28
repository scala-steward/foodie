module Pages.Ingredients.FoodGroup exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Util.DictList as DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias FoodGroup ingredientId ingredient update foodId food creation =
    { ingredients : DictList ingredientId (IngredientState ingredient update)
    , foods : DictList foodId food
    , foodsToAdd : DictList foodId creation
    , pagination : Pagination
    , foodsSearchString : String
    }


type alias IngredientState ingredient update =
    Editing ingredient update


initial : FoodGroup ingredientId ingredient update foodId food creation
initial =
    { ingredients = DictList.empty
    , foods = DictList.empty
    , foodsToAdd = DictList.empty
    , pagination = Pagination.initial
    , foodsSearchString = ""
    }


lenses :
    { ingredients : Lens (FoodGroup ingredientId ingredient update foodId food creation) (DictList ingredientId (IngredientState ingredient update))
    , foods : Lens (FoodGroup ingredientId ingredient update foodId food creation) (DictList foodId food)
    , foodsToAdd : Lens (FoodGroup ingredientId ingredient update foodId food creation) (DictList foodId creation)
    , pagination : Lens (FoodGroup ingredientId ingredient update foodId food creation) Pagination
    , foodsSearchString : Lens (FoodGroup ingredientId ingredient update foodId food creation) String
    }
lenses =
    { ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , foods = Lens .foods (\b a -> { a | foods = b })
    , foodsToAdd = Lens .foodsToAdd (\b a -> { a | foodsToAdd = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
    }
