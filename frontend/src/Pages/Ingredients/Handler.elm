module Pages.Ingredients.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Api.Types.Ingredient exposing (Ingredient)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup
import Pages.Ingredients.FoodGroupHandler as FoodGroupHandler
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Page as Page
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Pages.Ingredients.Recipe.Handler
import Pages.Ingredients.Requests as Requests
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Ports exposing (doFetchFoods, storeFoods)
import Result.Extra
import Util.DictList as DictList
import Util.HttpUtil as HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess flags.recipeId
    , initialFetch
        flags.authorizedAccess
        flags.recipeId
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchIngredients authorizedAccess recipeId |> Cmd.map Page.IngredientMsg
        , Requests.fetchComplexIngredients authorizedAccess recipeId |> Cmd.map Page.ComplexIngredientMsg
        , Pages.Ingredients.Recipe.Handler.initialFetch authorizedAccess recipeId |> Cmd.map Page.RecipeMsg
        , doFetchFoods ()
        , Requests.fetchComplexFoods authorizedAccess |> Cmd.map Page.ComplexIngredientMsg
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.UpdateFoods string ->
            updateFoods model string

        Page.ChangeFoodsMode foodsMode ->
            changeFoodsMode model foodsMode

        Page.IngredientMsg ingredientsGroupMsg ->
            let
                -- Todo: Most likely it is sensible to extract this function to a sub-model.
                updateSubModel =
                    FoodGroupHandler.updateLogic
                        { idOfIngredient = .id
                        , idOfUpdate = .ingredientId
                        , idOfFood = .id
                        , foodIdOfIngredient = .foodId
                        , foodIdOfCreation = .foodId
                        , toUpdate = IngredientUpdateClientInput.from
                        , toCreation = \food recipeId -> IngredientCreationClientInput.default recipeId food.id (food.measures |> List.head |> Maybe.Extra.unwrap 0 .id)
                        , createIngredient = \authorizedAccess _ -> IngredientCreationClientInput.toCreation >> Requests.createIngredient authorizedAccess
                        , saveIngredient = \authorizedAccess _ updateInput -> IngredientUpdateClientInput.to updateInput |> Requests.saveIngredient authorizedAccess
                        , deleteIngredient = \authorizedAccess _ -> Requests.deleteIngredient authorizedAccess
                        , storeFoods =
                            Encode.list encoderFood
                                >> Encode.encode 0
                                >> storeFoods
                        }
            in
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.ingredientsGroup
                , mainSubModelLens = Page.lenses.main.ingredientsGroup
                , subModelOf = Page.ingredientsGroupSubModel
                , fromInitToMain = Page.initialToMain
                , updateSubModel = updateSubModel
                , toMsg = Page.IngredientMsg
                }
                ingredientsGroupMsg
                model

        Page.ComplexIngredientMsg complexIngredientsGroupMsg ->
            let
                -- Todo: Most likely it is sensible to extract this function to a sub-model.
                updateSubModel =
                    FoodGroupHandler.updateLogic
                        { idOfIngredient = .complexFoodId
                        , idOfUpdate = .complexFoodId
                        , idOfFood = .recipeId
                        , foodIdOfIngredient = .complexFoodId
                        , foodIdOfCreation = .complexFoodId
                        , toUpdate = ComplexIngredientClientInput.from
                        , toCreation = \food _ -> ComplexIngredientClientInput.fromFood food
                        , createIngredient =
                            \authorizedAccess recipeId ->
                                ComplexIngredientClientInput.to
                                    >> Requests.createComplexIngredient authorizedAccess recipeId
                        , saveIngredient = \authorizedAccess recipeId updateInput -> ComplexIngredientClientInput.to updateInput |> Requests.saveComplexIngredient authorizedAccess recipeId
                        , deleteIngredient = Requests.deleteComplexIngredient
                        , storeFoods = \_ -> Cmd.none
                        }
            in
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.complexIngredientsGroup
                , mainSubModelLens = Page.lenses.main.complexIngredientsGroup
                , subModelOf = Page.complexIngredientsGroupSubModel
                , fromInitToMain = Page.initialToMain
                , updateSubModel = updateSubModel
                , toMsg = Page.ComplexIngredientMsg
                }
                complexIngredientsGroupMsg
                model

        Page.RecipeMsg recipeMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.recipe
                , mainSubModelLens = Page.lenses.main.recipe
                , subModelOf = Page.recipeSubModel
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.Ingredients.Recipe.Handler.updateLogic
                , toMsg = Page.RecipeMsg
                }
                recipeMsg
                model


updateFoods : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
updateFoods model =
    Decode.decodeString (Decode.list decoderFood)
        >> Result.Extra.unpack (\error -> ( error |> HttpUtil.jsonErrorToError |> Tristate.toError model, Cmd.none ))
            (\foods ->
                ( model
                    |> Tristate.mapInitial
                        ((Page.lenses.initial.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.initial.foods).set
                            (foods |> Just |> Maybe.Extra.filter (List.isEmpty >> not) |> Maybe.map (DictList.fromListWithKey .id))
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
                , model
                    |> Tristate.lenses.initial.getOption
                    |> Maybe.Extra.filter (always (foods |> List.isEmpty))
                    |> Maybe.Extra.unwrap Cmd.none
                        (\initial ->
                            Requests.fetchFoods
                                { configuration = model.configuration
                                , jwt = initial.jwt
                                }
                                |> Cmd.map Page.IngredientMsg
                        )
                )
            )


changeFoodsMode : Page.Model -> Page.FoodsMode -> ( Page.Model, Cmd Page.LogicMsg )
changeFoodsMode model foodsMode =
    ( model
        |> Tristate.mapMain (Page.lenses.main.foodsMode.set foodsMode)
    , Cmd.none
    )


setSearchString :
    { searchStringLens : Lens Page.Main String
    , foodGroupLens : Lens Page.Main (FoodGroup.Main ingredientId ingredient update foodId food creation)
    }
    -> Page.Model
    -> String
    -> ( Page.Model, Cmd Page.LogicMsg )
setSearchString lenses model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    lenses.searchStringLens
                , paginationSettingsLens =
                    lenses.foodGroupLens
                        |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.ingredients
                }
                string
            )
    , Cmd.none
    )
