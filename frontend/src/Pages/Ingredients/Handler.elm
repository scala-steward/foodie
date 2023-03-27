module Pages.Ingredients.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Api.Types.Recipe exposing (Recipe)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup
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
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch
        flags.authorizedAccess
        flags.recipeId
        |> Cmd.map Tristate.Logic
    )


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchIngredients authorizedAccess recipeId
        , Requests.fetchComplexIngredients authorizedAccess recipeId
        , Pages.Ingredients.Recipe.Handler.initialFetch authorizedAccess recipeId |> Cmd.map Page.RecipeMsg
        , doFetchFoods ()
        , Requests.fetchComplexFoods authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.UpdateIngredient ingredientUpdateClientInput ->
            updateIngredient model ingredientUpdateClientInput

        Page.UpdateComplexIngredient complexIngredient ->
            updateComplexIngredient model complexIngredient

        Page.SaveIngredientEdit ingredientUpdateClientInput ->
            saveIngredientEdit model ingredientUpdateClientInput

        Page.SaveComplexIngredientEdit complexIngredientClientInput ->
            saveComplexIngredientEdit model complexIngredientClientInput

        Page.GotSaveIngredientResponse result ->
            gotSaveIngredientResponse model result

        Page.GotSaveComplexIngredientResponse result ->
            gotSaveComplexIngredientResponse model result

        Page.ToggleIngredientControls ingredientId ->
            toggleIngredientControls model ingredientId

        Page.EnterEditIngredient ingredientId ->
            enterEditIngredient model ingredientId

        Page.ToggleComplexIngredientControls complexIngredientId ->
            toggleComplexIngredientControls model complexIngredientId

        Page.EnterEditComplexIngredient complexIngredientId ->
            enterEditComplexIngredient model complexIngredientId

        Page.ExitEditIngredientAt ingredientId ->
            exitEditIngredientAt model ingredientId

        Page.ExitEditComplexIngredientAt complexIngredientId ->
            exitEditComplexIngredientAt model complexIngredientId

        Page.RequestDeleteIngredient ingredientId ->
            requestDeleteIngredient model ingredientId

        Page.ConfirmDeleteIngredient ingredientId ->
            confirmDeleteIngredient model ingredientId

        Page.CancelDeleteIngredient ingredientId ->
            cancelDeleteIngredient model ingredientId

        Page.RequestDeleteComplexIngredient complexIngredientId ->
            requestDeleteComplexIngredient model complexIngredientId

        Page.ConfirmDeleteComplexIngredient complexIngredientId ->
            confirmDeleteComplexIngredient model complexIngredientId

        Page.CancelDeleteComplexIngredient complexIngredientId ->
            cancelDeleteComplexIngredient model complexIngredientId

        Page.GotDeleteIngredientResponse ingredientId result ->
            gotDeleteIngredientResponse model ingredientId result

        Page.GotDeleteComplexIngredientResponse complexIngredientId result ->
            gotDeleteComplexIngredientResponse model complexIngredientId result

        Page.GotFetchIngredientsResponse result ->
            gotFetchIngredientsResponse model result

        Page.GotFetchComplexIngredientsResponse result ->
            gotFetchComplexIngredientsResponse model result

        Page.GotFetchFoodsResponse result ->
            gotFetchFoodsResponse model result

        Page.GotFetchComplexFoodsResponse result ->
            gotFetchComplexFoodsResponse model result

        Page.UpdateFoods string ->
            updateFoods model string

        Page.SetFoodsSearchString string ->
            setFoodsSearchString model string

        Page.SetComplexFoodsSearchString string ->
            setComplexFoodsSearchString model string

        Page.SelectFood food ->
            selectFood model food

        Page.SelectComplexFood complexFood ->
            selectComplexFood model complexFood

        Page.DeselectFood foodId ->
            deselectFood model foodId

        Page.DeselectComplexFood complexFoodId ->
            deselectComplexFood model complexFoodId

        Page.AddFood foodId ->
            addFood model foodId

        Page.AddComplexFood complexFoodId ->
            addComplexFood model complexFoodId

        Page.GotAddFoodResponse result ->
            gotAddFoodResponse model result

        Page.GotAddComplexFoodResponse result ->
            gotAddComplexFoodResponse model result

        Page.UpdateAddFood ingredientCreationClientInput ->
            updateAddFood model ingredientCreationClientInput

        Page.UpdateAddComplexFood complexIngredientClientInput ->
            updateAddComplexFood model complexIngredientClientInput

        Page.SetIngredientsPagination pagination ->
            setIngredientsPagination model pagination

        Page.SetComplexIngredientsPagination pagination ->
            setComplexIngredientsPagination model pagination

        Page.ChangeFoodsMode foodsMode ->
            changeFoodsMode model foodsMode

        Page.SetIngredientsSearchString string ->
            setIngredientsSearchString model string

        Page.SetComplexIngredientsSearchString string ->
            setComplexIngredientsSearchString model string

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


mapIngredientStateById : IngredientId -> (Page.PlainIngredientState -> Page.PlainIngredientState) -> Page.Model -> Page.Model
mapIngredientStateById ingredientId =
    (Page.lenses.main.ingredientsGroup
        |> Compose.lensWithLens FoodGroup.lenses.main.ingredients
        |> LensUtil.updateById ingredientId
    )
        >> Tristate.mapMain


mapComplexIngredientStateById : ComplexIngredientId -> (Page.ComplexIngredientState -> Page.ComplexIngredientState) -> Page.Model -> Page.Model
mapComplexIngredientStateById complexIngredientId =
    (Page.lenses.main.complexIngredientsGroup
        |> Compose.lensWithLens FoodGroup.lenses.main.ingredients
        |> LensUtil.updateById complexIngredientId
    )
        >> Tristate.mapMain


updateIngredient : Page.Model -> IngredientUpdateClientInput -> ( Page.Model, Cmd msg )
updateIngredient model ingredientUpdateClientInput =
    ( model
        |> mapIngredientStateById ingredientUpdateClientInput.ingredientId
            (Editing.lenses.update.set ingredientUpdateClientInput)
    , Cmd.none
    )


updateComplexIngredient : Page.Model -> ComplexIngredientClientInput -> ( Page.Model, Cmd msg )
updateComplexIngredient model complexIngredientClientInput =
    ( model
        |> mapComplexIngredientStateById complexIngredientClientInput.complexFoodId
            (Editing.lenses.update.set complexIngredientClientInput)
    , Cmd.none
    )


saveIngredientEdit : Page.Model -> IngredientUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
saveIngredientEdit model ingredientUpdateClientInput =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                ingredientUpdateClientInput
                    |> IngredientUpdateClientInput.to
                    |> Requests.saveIngredient
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
            )
    )


saveComplexIngredientEdit : Page.Model -> ComplexIngredientClientInput -> ( Page.Model, Cmd Page.LogicMsg )
saveComplexIngredientEdit model complexIngredientClientInput =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                complexIngredientClientInput
                    |> ComplexIngredientClientInput.to
                    |> Requests.saveComplexIngredient
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                        main.recipe.recipe.original.id
            )
    )


gotSaveIngredientResponse : Page.Model -> Result Error Ingredient -> ( Page.Model, Cmd msg )
gotSaveIngredientResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\ingredient ->
                model
                    |> mapIngredientStateById ingredient.id
                        (Editing.asViewWithElement ingredient)
            )
    , Cmd.none
    )


gotSaveComplexIngredientResponse : Page.Model -> Result Error ComplexIngredient -> ( Page.Model, Cmd msg )
gotSaveComplexIngredientResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexIngredient ->
                model
                    |> mapComplexIngredientStateById complexIngredient.complexFoodId
                        (Editing.asViewWithElement complexIngredient)
            )
    , Cmd.none
    )


toggleIngredientControls : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.LogicMsg )
toggleIngredientControls model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toggleControls
    , Cmd.none
    )


enterEditIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.LogicMsg )
enterEditIngredient model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId (Editing.toUpdate IngredientUpdateClientInput.from)
    , Cmd.none
    )


toggleComplexIngredientControls : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.LogicMsg )
toggleComplexIngredientControls model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toggleControls
    , Cmd.none
    )


enterEditComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.LogicMsg )
enterEditComplexIngredient model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId (Editing.toUpdate ComplexIngredientClientInput.from)
    , Cmd.none
    )


exitEditIngredientAt : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.LogicMsg )
exitEditIngredientAt model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toView
    , Cmd.none
    )


exitEditComplexIngredientAt : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.LogicMsg )
exitEditComplexIngredientAt model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toView
    , Cmd.none
    )


requestDeleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteIngredient model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toDelete
    , Cmd.none
    )


confirmDeleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteIngredient model ingredientId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteIngredient
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    ingredientId
            )
    )


cancelDeleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteIngredient model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toView
    , Cmd.none
    )


requestDeleteComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteComplexIngredient model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toDelete
    , Cmd.none
    )


confirmDeleteComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteComplexIngredient model complexIngredientId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteComplexIngredient
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    main.recipe.recipe.original.id
                    complexIngredientId
            )
    )


cancelDeleteComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteComplexIngredient model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toView
    , Cmd.none
    )


gotDeleteIngredientResponse : Page.Model -> IngredientId -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteIngredientResponse model ingredientId result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (model
                |> Tristate.mapMain
                    (LensUtil.deleteAtId ingredientId
                        (Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.ingredients)
                    )
                |> always
            )
    , Cmd.none
    )


gotDeleteComplexIngredientResponse : Page.Model -> ComplexIngredientId -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteComplexIngredientResponse model complexIngredientId result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (model
                |> Tristate.mapMain
                    (LensUtil.deleteAtId complexIngredientId
                        (Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.ingredients)
                    )
                |> always
            )
    , Cmd.none
    )


gotFetchIngredientsResponse : Page.Model -> Result Error (List Ingredient) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchIngredientsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\ingredients ->
                model
                    |> Tristate.mapInitial
                        ((Page.lenses.initial.ingredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.initial.ingredients
                         ).set
                            (ingredients |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .id) |> Just)
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchComplexIngredientsResponse : Page.Model -> Result Error (List ComplexIngredient) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchComplexIngredientsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexIngredients ->
                model
                    |> Tristate.mapInitial
                        ((Page.lenses.initial.complexIngredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.initial.ingredients
                         ).set
                            (complexIngredients |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .complexFoodId) |> Just)
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchFoodsResponse : Page.Model -> Result Error (List Food) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchFoodsResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
            (\foods ->
                ( model
                    |> Tristate.mapInitial
                        ((Page.lenses.initial.ingredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.initial.foods
                         ).set
                            (foods |> DictList.fromListWithKey .id |> Just)
                        )
                , foods
                    |> Encode.list encoderFood
                    |> Encode.encode 0
                    |> storeFoods
                )
            )


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexFoods ->
                model
                    |> Tristate.mapInitial
                        ((Page.lenses.initial.complexIngredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.initial.foods
                         ).set
                            (complexFoods |> DictList.fromListWithKey .recipeId |> Just)
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


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
                        )
                )
            )


setFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setFoodsSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.ingredientsGroup
                        |> Compose.lensWithLens FoodGroup.lenses.main.foodsSearchString
                , paginationSettingsLens =
                    Page.lenses.main.ingredientsGroup
                        |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.foods
                }
                string
            )
    , Cmd.none
    )


setComplexFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setComplexFoodsSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.complexIngredientsGroup
                        |> Compose.lensWithLens FoodGroup.lenses.main.foodsSearchString
                , paginationSettingsLens =
                    Page.lenses.main.complexIngredientsGroup
                        |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.foods
                }
                string
            )
    , Cmd.none
    )


selectFood : Page.Model -> Food -> ( Page.Model, Cmd msg )
selectFood model food =
    ( model
        |> Tristate.mapMain
            (\main ->
                main
                    |> LensUtil.updateById food.id
                        (Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                        (Editing.toUpdate (\_ -> IngredientCreationClientInput.default main.recipe.recipe.original.id food.id (food.measures |> List.head |> Maybe.Extra.unwrap 0 .id)))
            )
    , Cmd.none
    )


selectComplexFood : Page.Model -> ComplexFood -> ( Page.Model, Cmd msg )
selectComplexFood model complexFood =
    ( model
        |> Tristate.mapMain
            (LensUtil.updateById complexFood.recipeId
                (Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                (Editing.toUpdate (\_ -> ComplexIngredientClientInput.fromFood complexFood))
            )
    , Cmd.none
    )


deselectFood : Page.Model -> FoodId -> ( Page.Model, Cmd Page.LogicMsg )
deselectFood model foodId =
    ( model
        |> Tristate.mapMain
            (LensUtil.updateById foodId
                (Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                Editing.toView
            )
    , Cmd.none
    )


deselectComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
deselectComplexFood model complexFoodId =
    ( model
        |> Tristate.mapMain
            (LensUtil.updateById complexFoodId
                (Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                Editing.toView
            )
    , Cmd.none
    )


addFood : Page.Model -> FoodId -> ( Page.Model, Cmd Page.LogicMsg )
addFood model foodId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> (Page.lenses.main.ingredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.main.foods
                            |> Compose.lensWithOptional (LensUtil.dictByKey foodId)
                            |> Compose.optionalWithOptional Editing.lenses.update
                       ).getOption
                    |> Maybe.map
                        (IngredientCreationClientInput.toCreation
                            >> Requests.addFood
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


addComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.LogicMsg )
addComplexFood model complexFoodId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> (Page.lenses.main.complexIngredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.main.foods
                            |> Compose.lensWithOptional (LensUtil.dictByKey complexFoodId)
                            |> Compose.optionalWithOptional Editing.lenses.update
                       ).getOption
                    |> Maybe.map
                        (ComplexIngredientClientInput.to
                            >> Requests.addComplexFood
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                                main.recipe.recipe.original.id
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddFoodResponse : Page.Model -> Result Error Ingredient -> ( Page.Model, Cmd Page.LogicMsg )
gotAddFoodResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\ingredient ->
                model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId ingredient.id
                            (Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.ingredients)
                            (ingredient |> Editing.asView)
                            >> LensUtil.updateById ingredient.foodId
                                (Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                                Editing.toView
                        )
            )
    , Cmd.none
    )


gotAddComplexFoodResponse : Page.Model -> Result Error ComplexIngredient -> ( Page.Model, Cmd Page.LogicMsg )
gotAddComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\complexIngredient ->
                model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId complexIngredient.complexFoodId
                            (Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.ingredients)
                            (complexIngredient |> Editing.asView)
                            >> LensUtil.updateById complexIngredient.complexFoodId
                                (Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                                Editing.toView
                        )
            )
    , Cmd.none
    )


updateAddFood : Page.Model -> IngredientCreationClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateAddFood model ingredientCreationClientInput =
    ( model
        |> Tristate.mapMain
            (LensUtil.updateById ingredientCreationClientInput.foodId
                (Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                (Editing.lenses.update.set ingredientCreationClientInput)
            )
    , Cmd.none
    )


updateAddComplexFood : Page.Model -> ComplexIngredientClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateAddComplexFood model complexIngredientClientInput =
    ( model
        |> Tristate.mapMain
            (LensUtil.updateById complexIngredientClientInput.complexFoodId
                (Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.foods)
                (Editing.lenses.update.set complexIngredientClientInput)
            )
    , Cmd.none
    )


setIngredientsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setIngredientsPagination model pagination =
    ( model
        |> Tristate.mapMain ((Page.lenses.main.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.pagination).set pagination)
    , Cmd.none
    )


setComplexIngredientsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setComplexIngredientsPagination model pagination =
    ( model |> Tristate.mapMain ((Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.pagination).set pagination)
    , Cmd.none
    )


changeFoodsMode : Page.Model -> Page.FoodsMode -> ( Page.Model, Cmd Page.LogicMsg )
changeFoodsMode model foodsMode =
    ( model
        |> Tristate.mapMain (Page.lenses.main.foodsMode.set foodsMode)
    , Cmd.none
    )


setIngredientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setIngredientsSearchString =
    setSearchString
        { searchStringLens = Page.lenses.main.ingredientsSearchString
        , foodGroupLens = Page.lenses.main.ingredientsGroup
        }


setComplexIngredientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setComplexIngredientsSearchString =
    setSearchString
        { searchStringLens = Page.lenses.main.complexIngredientsSearchString
        , foodGroupLens = Page.lenses.main.complexIngredientsGroup
        }


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
