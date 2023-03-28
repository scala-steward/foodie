module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Recipe.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate exposing (Status(..))
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipe : Pages.Ingredients.Recipe.Page.Main
    , ingredientsGroup : IngredientsGroup
    , complexIngredientsGroup : ComplexIngredientsGroup
    , foodsMode : FoodsMode
    , ingredientsSearchString : String
    , complexIngredientsSearchString : String
    }


type alias Initial =
    { jwt : JWT
    , recipe : Pages.Ingredients.Recipe.Page.Initial
    , ingredientsGroup : FoodGroup.Initial IngredientId Ingredient IngredientUpdateClientInput FoodId Food
    , complexIngredientsGroup : FoodGroup.Initial ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood
    }


recipeSubModel : Model -> Pages.Ingredients.Recipe.Page.Model
recipeSubModel model =
    { configuration = model.configuration
    , status =
        Tristate.fold
            { onInitial = .recipe >> Tristate.Initial
            , onMain = .recipe >> Tristate.Main
            , onError =
                \es ->
                    Tristate.Error
                        { errorExplanation = es.errorExplanation
                        , previousMain = es.previousMain |> Maybe.map .recipe
                        }
            }
            model
    }


ingredientsGroupSubModel : Model -> IngredientsGroupModel
ingredientsGroupSubModel model =
    { configuration = model.configuration
    , status =
        Tristate.fold
            { onInitial = .ingredientsGroup >> Tristate.Initial
            , onMain = .ingredientsGroup >> Tristate.Main
            , onError =
                \es ->
                    Tristate.Error
                        { errorExplanation = es.errorExplanation
                        , previousMain = es.previousMain |> Maybe.map .ingredientsGroup
                        }
            }
            model
    }


complexIngredientsGroupSubModel : Model -> ComplexIngredientsGroupModel
complexIngredientsGroupSubModel model =
    { configuration = model.configuration
    , status =
        Tristate.fold
            { onInitial = .complexIngredientsGroup >> Tristate.Initial
            , onMain = .complexIngredientsGroup >> Tristate.Main
            , onError =
                \es ->
                    Tristate.Error
                        { errorExplanation = es.errorExplanation
                        , previousMain = es.previousMain |> Maybe.map .complexIngredientsGroup
                        }
            }
            model
    }


initial : AuthorizedAccess -> RecipeId -> Model
initial authorizedAccess recipeId =
    { jwt = authorizedAccess.jwt
    , recipe = Pages.Ingredients.Recipe.Page.initialWith authorizedAccess.jwt
    , ingredientsGroup = FoodGroup.initialWith authorizedAccess.jwt recipeId
    , complexIngredientsGroup = FoodGroup.initialWith authorizedAccess.jwt recipeId
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.recipe
        |> Pages.Ingredients.Recipe.Page.initialToMain
        |> Maybe.andThen
            (\recipe ->
                i.ingredientsGroup
                    |> FoodGroup.initialToMain
                    |> Maybe.andThen
                        (\ingredientsGroup ->
                            i.complexIngredientsGroup
                                |> FoodGroup.initialToMain
                                |> Maybe.map
                                    (\complexIngredientsGroup ->
                                        { jwt = i.jwt
                                        , recipe = recipe
                                        , ingredientsGroup = ingredientsGroup
                                        , complexIngredientsGroup = complexIngredientsGroup
                                        , foodsMode = Plain
                                        , ingredientsSearchString = ""
                                        , complexIngredientsSearchString = ""
                                        }
                                    )
                        )
            )


type alias IngredientsGroup =
    FoodGroup.Main IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput


type alias IngredientsGroupMsg =
    FoodGroup.LogicMsg IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput


type alias IngredientsGroupModel =
    FoodGroup.Model IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput


type alias ComplexIngredientsGroup =
    FoodGroup.Main ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput


type alias ComplexIngredientsGroupMsg =
    FoodGroup.LogicMsg ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput


type alias ComplexIngredientsGroupModel =
    FoodGroup.Model ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput


type alias PlainIngredientState =
    FoodGroup.IngredientState Ingredient IngredientUpdateClientInput


type alias ComplexIngredientState =
    FoodGroup.IngredientState ComplexIngredient ComplexIngredientClientInput


type alias FoodMap =
    DictList FoodId (Editing Food IngredientCreationClientInput)


type alias ComplexFoodMap =
    DictList ComplexFoodId (Editing ComplexFood ComplexIngredientClientInput)


type alias RecipeMap =
    DictList RecipeId Recipe


type alias PlainIngredientStateMap =
    DictList IngredientId PlainIngredientState


type alias ComplexIngredientStateMap =
    DictList ComplexIngredientId ComplexIngredientState


type FoodsMode
    = Plain
    | Complex


lenses :
    { initial :
        { ingredientsGroup : Lens Initial (FoodGroup.Initial IngredientId Ingredient IngredientUpdateClientInput FoodId Food)
        , complexIngredientsGroup : Lens Initial (FoodGroup.Initial ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood)
        , recipe : Lens Initial Pages.Ingredients.Recipe.Page.Initial
        }
    , main :
        { ingredientsGroup : Lens Main IngredientsGroup
        , complexIngredientsGroup : Lens Main ComplexIngredientsGroup
        , recipe : Lens Main Pages.Ingredients.Recipe.Page.Main
        , foodsMode : Lens Main FoodsMode
        , ingredientsSearchString : Lens Main String
        , complexIngredientsSearchString : Lens Main String
        }
    }
lenses =
    { initial =
        { ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
        , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
        , recipe = Lens .recipe (\b a -> { a | recipe = b })
        }
    , main =
        { ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
        , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
        , recipe = Lens .recipe (\b a -> { a | recipe = b })
        , foodsMode = Lens .foodsMode (\b a -> { a | foodsMode = b })
        , ingredientsSearchString = Lens .ingredientsSearchString (\b a -> { a | ingredientsSearchString = b })
        , complexIngredientsSearchString = Lens .complexIngredientsSearchString (\b a -> { a | complexIngredientsSearchString = b })
        }
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = UpdateFoods String
    | ChangeFoodsMode FoodsMode
    | IngredientMsg IngredientsGroupMsg
    | ComplexIngredientMsg ComplexIngredientsGroupMsg
    | RecipeMsg Pages.Ingredients.Recipe.Page.LogicMsg


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
