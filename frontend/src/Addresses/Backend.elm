module Addresses.Backend exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ComplexFoodId, FoodId, IngredientId, MealEntryId, MealId, NutrientCode, ProfileId, RecipeId, ReferenceMapId)
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
    , update : RecipeId -> ResourcePattern
    , delete : RecipeId -> ResourcePattern
    , duplicate : RecipeId -> ResourcePattern
    , rescale : RecipeId -> ResourcePattern
    , ingredients :
        { allOf : RecipeId -> ResourcePattern
        , create : RecipeId -> ResourcePattern
        , update : RecipeId -> IngredientId -> ResourcePattern
        , delete : RecipeId -> IngredientId -> ResourcePattern
        }
    , complexIngredients :
        { allOf : RecipeId -> ResourcePattern
        , create : RecipeId -> ResourcePattern
        , update : RecipeId -> ComplexFoodId -> ResourcePattern
        , delete : RecipeId -> ComplexFoodId -> ResourcePattern
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

        ingredients recipeId =
            (::) ingredientsWord >> (::) (recipeId |> Uuid.toString) >> base

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
    , update = \recipeId -> patch <| base [ recipeId |> Uuid.toString ]
    , delete = \recipeId -> delete <| base <| [ recipeId |> Uuid.toString ]
    , duplicate = \recipeId -> post <| base <| [ recipeId |> Uuid.toString, duplicateWord ]
    , rescale = \recipeId -> patch <| base <| [ recipeId |> Uuid.toString, rescaleWord ]
    , ingredients =
        { allOf = \recipeId -> get <| base <| [ recipeId |> Uuid.toString, ingredientsWord ]
        , create = \recipeId -> post <| ingredients recipeId []
        , update =
            \recipeId ingredientId ->
                patch <|
                    base <|
                        (::) (recipeId |> Uuid.toString) <|
                            (::) ingredientsWord <|
                                [ ingredientId |> Uuid.toString ]
        , delete =
            \recipeId ingredientId ->
                delete <|
                    base <|
                        (::) (recipeId |> Uuid.toString) <|
                            (::) ingredientsWord <|
                                [ ingredientId |> Uuid.toString ]
        }
    , complexIngredients =
        { allOf = \recipeId -> get <| complexIngredients recipeId []
        , create = \recipeId -> post <| complexIngredients recipeId []
        , update = \recipeId complexIngredientId -> patch <| complexIngredients recipeId [ complexIngredientId |> Uuid.toString ]
        , delete = \recipeId complexIngredientId -> delete <| complexIngredients recipeId <| [ complexIngredientId |> Uuid.toString ]
        }
    }


meals :
    { all : ProfileId -> ResourcePattern
    , single : ProfileId -> MealId -> ResourcePattern
    , create : ProfileId -> ResourcePattern
    , update : ProfileId -> MealId -> ResourcePattern
    , delete : ProfileId -> MealId -> ResourcePattern
    , duplicate : ProfileId -> MealId -> ResourcePattern
    , entries :
        { allOf : ProfileId -> MealId -> ResourcePattern
        , create : ProfileId -> MealId -> ResourcePattern
        , update : ProfileId -> MealId -> MealEntryId -> ResourcePattern
        , delete : ProfileId -> MealId -> MealEntryId -> ResourcePattern
        }
    }
meals =
    let
        profilesWord =
            "profiles"

        mealsWord =
            "meals"

        base profileId =
            (::) mealsWord >> (::) (profileId |> Uuid.toString) >> (::) profilesWord

        entriesWord =
            "entries"

        entries profileId mealId =
            (::) entriesWord >> (::) (mealId |> Uuid.toString) >> base profileId

        duplicateWord =
            "duplicate"
    in
    { all = \profileId -> get <| base profileId []
    , single = \profileId mealId -> get <| base profileId [ mealId |> Uuid.toString ]
    , create = \profileId -> post <| base profileId []
    , update = \profileId mealId -> patch <| base profileId [ mealId |> Uuid.toString ]
    , delete = \profileId mealId -> delete <| base profileId <| [ mealId |> Uuid.toString ]
    , duplicate = \profileId mealId -> post <| base profileId <| [ mealId |> Uuid.toString, duplicateWord ]
    , entries =
        { allOf = \profileId mealId -> get <| entries profileId mealId []
        , create = \profileId mealId -> post <| entries profileId mealId []
        , update =
            \profileId mealId mealEntryId ->
                patch <| entries profileId mealId [ mealEntryId |> Uuid.toString ]
        , delete =
            \profileId mealId mealEntryId ->
                delete <|
                    entries profileId mealId [ mealEntryId |> Uuid.toString ]
        }
    }


stats :
    { all :
        ProfileId
        ->
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

        profilesWord =
            "profiles"
    in
    { all = \profileId interval -> getQ (base [ profilesWord, Uuid.toString profileId ]) (Maybe.Extra.values [ interval.from, interval.to ])
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
    , update : ReferenceMapId -> ResourcePattern
    , delete : ReferenceMapId -> ResourcePattern
    , duplicate : ReferenceMapId -> ResourcePattern
    , entries :
        { allOf : ReferenceMapId -> ResourcePattern
        , create : ReferenceMapId -> ResourcePattern
        , update : ReferenceMapId -> NutrientCode -> ResourcePattern
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
    in
    { all = get <| base <| []
    , allTrees = get <| base <| (::) treesWord <| []
    , single = \referenceMapId -> get <| base <| [ referenceMapId |> Uuid.toString ]
    , create = post <| base []
    , update = \referenceMapId -> patch <| base [ referenceMapId |> Uuid.toString ]
    , delete = \referenceMapId -> delete <| base <| [ referenceMapId |> Uuid.toString ]
    , duplicate = \referenceMapId -> post <| base <| [ referenceMapId |> Uuid.toString, duplicateWord ]
    , entries =
        { allOf = \referenceMapId -> get <| base <| [ referenceMapId |> Uuid.toString, entriesWord ]
        , create = \referenceMapId -> post <| base [ referenceMapId |> Uuid.toString, entriesWord ]
        , update =
            \referenceMapId nutrientCode ->
                patch <|
                    base <|
                        (::) (referenceMapId |> Uuid.toString) <|
                            (::) entriesWord <|
                                [ String.fromInt nutrientCode ]
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
    , update : ComplexFoodId -> ResourcePattern
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
    , update = \complexFoodId -> patch <| base [ complexFoodId |> Uuid.toString ]
    , delete = \complexFoodId -> delete <| base <| [ complexFoodId |> Uuid.toString ]
    }


profiles :
    { all : ResourcePattern
    , single : ProfileId -> ResourcePattern
    , create : ResourcePattern
    , update : ProfileId -> ResourcePattern
    , delete : ProfileId -> ResourcePattern
    }
profiles =
    let
        base =
            (::) "profiles"
    in
    { all = get <| base <| []
    , single = \profileId -> get <| base <| [ profileId |> Uuid.toString ]
    , create = post <| base []
    , update = \profileId -> patch <| base [ profileId |> Uuid.toString ]
    , delete = \profileId -> delete <| base <| [ profileId |> Uuid.toString ]
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
