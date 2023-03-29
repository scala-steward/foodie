module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Complex.Page
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Plain.Page
import Pages.Ingredients.Recipe.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page as ChoiceGroup
import Pages.View.Tristate as Tristate exposing (Status(..))
import Pages.View.TristateUtil as TristateUtil
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipe : Pages.Ingredients.Recipe.Page.Main
    , ingredientsGroup : Pages.Ingredients.Plain.Page.Main
    , complexIngredientsGroup : Pages.Ingredients.Complex.Page.Main
    , foodsMode : FoodsMode
    , ingredientsSearchString : String
    , complexIngredientsSearchString : String
    }


type alias Initial =
    { jwt : JWT
    , recipe : Pages.Ingredients.Recipe.Page.Initial
    , ingredientsGroup : ChoiceGroup.Initial RecipeId IngredientId Ingredient FoodId Food
    , complexIngredientsGroup : ChoiceGroup.Initial RecipeId ComplexIngredientId ComplexIngredient ComplexFoodId ComplexFood
    }


recipeSubModel : Model -> Pages.Ingredients.Recipe.Page.Model
recipeSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.recipe
        , mainLens = lenses.main.recipe
        }


ingredientsGroupSubModel : Model -> Pages.Ingredients.Plain.Page.Model
ingredientsGroupSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.ingredientsGroup
        , mainLens = lenses.main.ingredientsGroup
        }


complexIngredientsGroupSubModel : Model -> Pages.Ingredients.Complex.Page.Model
complexIngredientsGroupSubModel =
    TristateUtil.subModelWith
        { initialLens = lenses.initial.complexIngredientsGroup
        , mainLens = lenses.main.complexIngredientsGroup
        }


initial : AuthorizedAccess -> RecipeId -> Model
initial authorizedAccess recipeId =
    { jwt = authorizedAccess.jwt
    , recipe = Pages.Ingredients.Recipe.Page.initialWith authorizedAccess.jwt
    , ingredientsGroup = ChoiceGroup.initialWith authorizedAccess.jwt recipeId
    , complexIngredientsGroup = ChoiceGroup.initialWith authorizedAccess.jwt recipeId
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.recipe
        |> Pages.Ingredients.Recipe.Page.initialToMain
        |> Maybe.andThen
            (\recipe ->
                i.ingredientsGroup
                    |> ChoiceGroup.initialToMain
                    |> Maybe.andThen
                        (\ingredientsGroup ->
                            i.complexIngredientsGroup
                                |> ChoiceGroup.initialToMain
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


type alias PlainIngredientState =
    Editing Ingredient IngredientUpdateClientInput


type alias ComplexIngredientState =
    Editing ComplexIngredient ComplexIngredientClientInput


type alias FoodMap =
    DictList FoodId (Editing Food IngredientCreationClientInput)


type alias ComplexFoodMap =
    DictList ComplexFoodId (Editing ComplexFood ComplexIngredientClientInput)


type alias PlainIngredientStateMap =
    DictList IngredientId PlainIngredientState


type alias ComplexIngredientStateMap =
    DictList ComplexIngredientId ComplexIngredientState


type FoodsMode
    = Plain
    | Complex


lenses :
    { initial :
        { ingredientsGroup : Lens Initial (ChoiceGroup.Initial RecipeId IngredientId Ingredient FoodId Food)
        , complexIngredientsGroup : Lens Initial (ChoiceGroup.Initial RecipeId ComplexIngredientId ComplexIngredient ComplexFoodId ComplexFood)
        , recipe : Lens Initial Pages.Ingredients.Recipe.Page.Initial
        }
    , main :
        { ingredientsGroup : Lens Main Pages.Ingredients.Plain.Page.Main
        , complexIngredientsGroup : Lens Main Pages.Ingredients.Complex.Page.Main
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
    | IngredientMsg Pages.Ingredients.Plain.Page.LogicMsg
    | ComplexIngredientMsg Pages.Ingredients.Complex.Page.LogicMsg
    | RecipeMsg Pages.Ingredients.Recipe.Page.LogicMsg


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
