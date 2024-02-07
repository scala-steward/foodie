module Addresses.Backend exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ComplexFoodId, FoodId, IngredientId, MealEntryId, MealId, NutrientCode, RecipeId, ReferenceMapId)
import Maybe.Extra
import Url.Builder exposing (QueryParameter)
import Util.HttpUtil as HttpUtil exposing (ResourcePattern)
import Uuid


recipes :
    { measures : ResourcePattern
    , foods : ResourcePattern
    , food : FoodId -> ResourcePattern
    , all : ResourcePattern
    , single : RecipeId -> ResourcePattern
    , create : ResourcePattern
    , update : ResourcePattern
    , delete : RecipeId -> ResourcePattern
    , duplicate : RecipeId -> ResourcePattern
    , rescale : RecipeId -> ResourcePattern
    , ingredients :
        { allOf : RecipeId -> ResourcePattern
        , create : ResourcePattern
        , update : ResourcePattern
        , delete : IngredientId -> ResourcePattern
        }
    , complexIngredients :
        { allOf : RecipeId -> ResourcePattern
        , create : RecipeId -> ResourcePattern
        , update : RecipeId -> ResourcePattern
        , delete : RecipeId -> IngredientId -> ResourcePattern
        }
    }
recipes =
    let
        base =
            (::) "recipes"

        ingredientsWord =
            "ingredients"

        duplicateWord =
            "duplicate"

        rescaleWord =
            "rescale"

        foodsWord =
            "foods"

        ingredients =
            (::) ingredientsWord >> base

        complexIngredientsWord =
            "complex-ingredients"

        complexIngredients recipeId =
            (::) complexIngredientsWord >> (::) (recipeId |> Uuid.toString) >> base
    in
    { measures = get <| base <| [ "measures" ]
    , foods = get <| base <| [ foodsWord ]
    , food = \foodId -> get <| base <| [ foodsWord, foodId |> String.fromInt ]
    , all = get <| base <| []
    , single = \recipeId -> get <| base <| [ recipeId |> Uuid.toString ]
    , create = post <| base []
    , update = patch <| base []
    , delete = \recipeId -> delete <| base <| [ recipeId |> Uuid.toString ]
    , duplicate = \recipeId -> post <| base <| [ recipeId |> Uuid.toString, duplicateWord ]
    , rescale = \recipeId -> patch <| base <| [ recipeId |> Uuid.toString, rescaleWord ]
    , ingredients =
        { allOf = \recipeId -> get <| base <| [ recipeId |> Uuid.toString, ingredientsWord ]
        , create = post <| ingredients []
        , update = patch <| ingredients []
        , delete = \ingredientId -> delete <| ingredients <| [ ingredientId |> Uuid.toString ]
        }
    , complexIngredients =
        { allOf = \recipeId -> get <| complexIngredients recipeId []
        , create = \recipeId -> post <| complexIngredients recipeId []
        , update = \recipeId -> patch <| complexIngredients recipeId []
        , delete = \recipeId complexIngredientId -> delete <| complexIngredients recipeId <| [ complexIngredientId |> Uuid.toString ]
        }
    }


meals :
    { all : ResourcePattern
    , single : MealId -> ResourcePattern
    , create : ResourcePattern
    , update : ResourcePattern
    , delete : MealId -> ResourcePattern
    , duplicate : MealId -> ResourcePattern
    , entries :
        { allOf : MealId -> ResourcePattern
        , create : ResourcePattern
        , update : ResourcePattern
        , delete : MealId -> MealEntryId -> ResourcePattern
        }
    }
meals =
    let
        base =
            (::) "meals"

        entriesWord =
            "entries"

        duplicateWord =
            "duplicate"

        entries =
            (::) entriesWord >> base
    in
    { all = get <| base <| []
    , single = \mealId -> get <| base <| [ mealId |> Uuid.toString ]
    , create = post <| base []
    , update = patch <| base []
    , delete = \mealId -> delete <| base <| [ mealId |> Uuid.toString ]
    , duplicate = \mealId -> post <| base <| [ mealId |> Uuid.toString, duplicateWord ]
    , entries =
        { allOf = \mealId -> get <| base <| [ mealId |> Uuid.toString, entriesWord ]
        , create = post <| entries []
        , update = patch <| entries []
        , delete =
            \mealId mealEntryId ->
                delete <|
                    base <|
                        (::) (mealId |> Uuid.toString) <|
                            (::) entriesWord <|
                                [ mealEntryId |> Uuid.toString ]
        }
    }


stats :
    { all :
        { from : Maybe QueryParameter
        , to : Maybe QueryParameter
        }
        -> ResourcePattern
    , complexFood : ComplexFoodId -> ResourcePattern
    , food : FoodId -> ResourcePattern
    , recipe : RecipeId -> ResourcePattern
    , meal : MealId -> ResourcePattern
    , nutrients : ResourcePattern
    , recipeOccurrences : ResourcePattern
    }
stats =
    let
        base =
            (::) "stats"
    in
    { all = \interval -> getQ (base []) (Maybe.Extra.values [ interval.from, interval.to ])
    , complexFood = \complexFoodId -> get <| base <| [ StatisticsVariant.complexFood, complexFoodId |> Uuid.toString ]
    , food = \foodId -> get <| base <| [ StatisticsVariant.food, foodId |> String.fromInt ]
    , recipe = \recipeId -> get <| base <| [ StatisticsVariant.recipe, recipeId |> Uuid.toString ]
    , meal = \mealId -> get <| base <| [ StatisticsVariant.meal, mealId |> Uuid.toString ]
    , nutrients = get <| base <| [ "nutrients" ]
    , recipeOccurrences = get <| base [ "recipe-occurrences" ]
    }


users :
    { login : ResourcePattern
    , logout : ResourcePattern
    , update : ResourcePattern
    , get : ResourcePattern
    , updatePassword : ResourcePattern
    , registration :
        { request : ResourcePattern
        , confirm : ResourcePattern
        }
    , recovery :
        { request : ResourcePattern
        , confirm : ResourcePattern
        , find : String -> ResourcePattern
        }
    , deletion :
        { request : ResourcePattern
        , confirm : ResourcePattern
        }
    }
users =
    let
        base =
            (::) "users"

        registration =
            (::) "registration" >> base

        recovery =
            (::) "recovery" >> base

        deletion =
            (::) "deletion" >> base
    in
    { login = post <| base <| [ "login" ]
    , logout = post <| base <| [ "logout" ]
    , update = patch <| base <| []
    , get = get <| base <| []
    , updatePassword = patch <| base <| [ "password" ]
    , registration =
        { request = post <| registration <| [ "request" ]
        , confirm = post <| registration <| [ "confirm" ]
        }
    , recovery =
        { request = post <| recovery <| [ "request" ]
        , confirm = post <| recovery <| [ "confirm" ]
        , find = \searchString -> get <| recovery <| [ "find", searchString ]
        }
    , deletion =
        { request = post <| deletion <| [ "request" ]
        , confirm = post <| deletion <| [ "confirm" ]
        }
    }


references :
    { all : ResourcePattern
    , allTrees : ResourcePattern
    , single : ReferenceMapId -> ResourcePattern
    , create : ResourcePattern
    , update : ResourcePattern
    , delete : ReferenceMapId -> ResourcePattern
    , duplicate : ReferenceMapId -> ResourcePattern
    , entries :
        { allOf : ReferenceMapId -> ResourcePattern
        , create : ResourcePattern
        , update : ResourcePattern
        , delete : ReferenceMapId -> NutrientCode -> ResourcePattern
        }
    }
references =
    let
        base =
            (::) "reference-maps"

        entriesWord =
            "entries"

        duplicateWord =
            "duplicate"

        treesWord =
            "trees"

        entries =
            (::) entriesWord >> base
    in
    { all = get <| base <| []
    , allTrees = get <| base <| (::) treesWord <| []
    , single = \referenceMapId -> get <| base <| [ referenceMapId |> Uuid.toString ]
    , create = post <| base []
    , update = patch <| base []
    , delete = \referenceMapId -> delete <| base <| [ referenceMapId |> Uuid.toString ]
    , duplicate = \referenceMapId -> post <| base <| [ referenceMapId |> Uuid.toString, duplicateWord ]
    , entries =
        { allOf = \referenceMapId -> get <| base <| [ referenceMapId |> Uuid.toString, entriesWord ]
        , create = post <| entries []
        , update = patch <| entries []
        , delete =
            \referenceMapId nutrientCode ->
                delete <|
                    base <|
                        (::) (referenceMapId |> Uuid.toString) <|
                            (::) entriesWord <|
                                [ String.fromInt nutrientCode ]
        }
    }


complexFoods :
    { all : ResourcePattern
    , single : ComplexFoodId -> ResourcePattern
    , create : ResourcePattern
    , update : ResourcePattern
    , delete : ComplexFoodId -> ResourcePattern
    }
complexFoods =
    let
        base =
            (::) "complex-foods"
    in
    { all = get <| base <| []
    , single = \complexFoodId -> get <| base <| [ complexFoodId |> Uuid.toString ]
    , create = post <| base []
    , update = patch <| base []
    , delete = \complexFoodId -> delete <| base <| [ complexFoodId |> Uuid.toString ]
    }


pattern : HttpUtil.Verb -> List String -> ResourcePattern
pattern verb path =
    { verb = verb
    , address = path
    , query = []
    }


get : List String -> ResourcePattern
get =
    pattern HttpUtil.GET


getQ : List String -> List QueryParameter -> ResourcePattern
getQ =
    ResourcePattern HttpUtil.GET


patch : List String -> ResourcePattern
patch =
    pattern HttpUtil.PATCH


post : List String -> ResourcePattern
post =
    pattern HttpUtil.POST


delete : List String -> ResourcePattern
delete =
    pattern HttpUtil.DELETE
