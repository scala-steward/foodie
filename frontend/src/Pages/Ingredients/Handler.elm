module Pages.Ingredients.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure, decoderMeasure, encoderMeasure)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
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
import Pages.Ingredients.RecipeInfo as RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Requests as Requests
import Pages.Ingredients.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Ports exposing (doFetchFoods, doFetchMeasures, storeFoods, storeMeasures)
import Result.Extra
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.Msg
initialFetch authorizedAccess recipeId =
    Cmd.batch
        [ Requests.fetchIngredients authorizedAccess recipeId
        , Requests.fetchComplexIngredients authorizedAccess recipeId
        , Requests.fetchRecipe authorizedAccess recipeId
        , doFetchFoods ()
        , Requests.fetchComplexFoods authorizedAccess
        , Requests.fetchRecipes authorizedAccess
        , doFetchMeasures ()
        ]


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , recipeId = flags.recipeId
      , ingredientsGroup = FoodGroup.initial
      , complexIngredientsGroup = FoodGroup.initial
      , measures = Dict.empty
      , recipeInfo = Nothing
      , allRecipes = Dict.empty
      , initialization = Loading Status.initial
      , foodsMode = Page.Plain
      , ingredientsSearchString = ""
      , complexIngredientsSearchString = ""
      }
    , initialFetch
        flags.authorizedAccess
        flags.recipeId
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
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

        Page.EnterEditIngredient ingredientId ->
            enterEditIngredient model ingredientId

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

        Page.GotFetchMeasuresResponse result ->
            gotFetchMeasuresResponse model result

        Page.GotFetchRecipeResponse result ->
            gotFetchRecipeResponse model result

        Page.GotFetchRecipesResponse result ->
            gotFetchRecipesResponse model result

        Page.UpdateFoods string ->
            updateFoods model string

        Page.UpdateMeasures string ->
            updateMeasures model string

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


mapIngredientStateById : IngredientId -> (Page.PlainIngredientState -> Page.PlainIngredientState) -> Page.Model -> Page.Model
mapIngredientStateById ingredientId =
    Page.lenses.ingredientsGroup
        |> Compose.lensWithLens FoodGroup.lenses.ingredients
        |> LensUtil.updateById ingredientId


mapComplexIngredientStateById : ComplexIngredientId -> (Page.ComplexIngredientState -> Page.ComplexIngredientState) -> Page.Model -> Page.Model
mapComplexIngredientStateById complexIngredientId =
    Page.lenses.complexIngredientsGroup
        |> Compose.lensWithLens FoodGroup.lenses.ingredients
        |> LensUtil.updateById complexIngredientId


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


saveIngredientEdit : Page.Model -> IngredientUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveIngredientEdit model ingredientUpdateClientInput =
    ( model
    , ingredientUpdateClientInput
        |> IngredientUpdateClientInput.to
        |> Requests.saveIngredient model.authorizedAccess
    )


saveComplexIngredientEdit : Page.Model -> ComplexIngredientClientInput -> ( Page.Model, Cmd Page.Msg )
saveComplexIngredientEdit model complexIngredientClientInput =
    ( model
    , complexIngredientClientInput
        |> ComplexIngredientClientInput.to
        |> Requests.saveComplexIngredient model.authorizedAccess model.recipeId
    )


gotSaveIngredientResponse : Page.Model -> Result Error Ingredient -> ( Page.Model, Cmd msg )
gotSaveIngredientResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\ingredient ->
                model
                    |> mapIngredientStateById ingredient.id
                        (Editing.asView ingredient |> always)
                    |> LensUtil.deleteAtId ingredient.foodId
                        (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            )
    , Cmd.none
    )


gotSaveComplexIngredientResponse : Page.Model -> Result Error ComplexIngredient -> ( Page.Model, Cmd msg )
gotSaveComplexIngredientResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexIngredient ->
                model
                    |> mapComplexIngredientStateById complexIngredient.complexFoodId
                        (Editing.asView complexIngredient |> always)
                    |> LensUtil.deleteAtId complexIngredient.complexFoodId
                        (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            )
    , Cmd.none
    )


enterEditIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
enterEditIngredient model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId (Editing.toUpdate IngredientUpdateClientInput.from)
    , Cmd.none
    )


enterEditComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.Msg )
enterEditComplexIngredient model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId (Editing.toUpdate ComplexIngredientClientInput.from)
    , Cmd.none
    )


exitEditIngredientAt : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
exitEditIngredientAt model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toView
    , Cmd.none
    )


exitEditComplexIngredientAt : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.Msg )
exitEditComplexIngredientAt model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toView
    , Cmd.none
    )


requestDeleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
requestDeleteIngredient model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toDelete
    , Cmd.none
    )


confirmDeleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteIngredient model ingredientId =
    ( model
    , Requests.deleteIngredient model.authorizedAccess ingredientId
    )


cancelDeleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteIngredient model ingredientId =
    ( model
        |> mapIngredientStateById ingredientId Editing.toView
    , Cmd.none
    )


requestDeleteComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.Msg )
requestDeleteComplexIngredient model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toDelete
    , Cmd.none
    )


confirmDeleteComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteComplexIngredient model complexIngredientId =
    ( model
    , Requests.deleteComplexIngredient model.authorizedAccess model.recipeId complexIngredientId
    )


cancelDeleteComplexIngredient : Page.Model -> ComplexIngredientId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteComplexIngredient model complexIngredientId =
    ( model
        |> mapComplexIngredientStateById complexIngredientId Editing.toView
    , Cmd.none
    )


gotDeleteIngredientResponse : Page.Model -> IngredientId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteIngredientResponse model ingredientId result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (model
                |> LensUtil.deleteAtId ingredientId
                    (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.ingredients)
                |> always
            )
    , Cmd.none
    )


gotDeleteComplexIngredientResponse : Page.Model -> ComplexIngredientId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteComplexIngredientResponse model complexIngredientId result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (model
                |> LensUtil.deleteAtId complexIngredientId
                    (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.ingredients)
                |> always
            )
    , Cmd.none
    )


gotFetchIngredientsResponse : Page.Model -> Result Error (List Ingredient) -> ( Page.Model, Cmd Page.Msg )
gotFetchIngredientsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\ingredients ->
                model
                    |> (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.ingredients).set
                        (ingredients |> List.map (\ingredient -> ( ingredient.id, ingredient |> Editing.asView )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.ingredients).set True
            )
    , Cmd.none
    )


gotFetchComplexIngredientsResponse : Page.Model -> Result Error (List ComplexIngredient) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexIngredientsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexIngredients ->
                model
                    |> (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.ingredients).set
                        (complexIngredients |> List.map (\complexIngredient -> ( complexIngredient.complexFoodId, complexIngredient |> Editing.asView )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexIngredients).set True
            )
    , Cmd.none
    )


gotFetchFoodsResponse : Page.Model -> Result Error (List Food) -> ( Page.Model, Cmd Page.Msg )
gotFetchFoodsResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( setError error model, Cmd.none ))
            (\foods ->
                ( LensUtil.set
                    foods
                    .id
                    (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foods)
                    model
                , foods
                    |> Encode.list encoderFood
                    |> Encode.encode 0
                    |> storeFoods
                )
            )


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFoods ->
                model
                    |> LensUtil.set
                        complexFoods
                        .recipeId
                        (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foods)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFoods).set True
            )
    , Cmd.none
    )


gotFetchMeasuresResponse : Page.Model -> Result Error (List Measure) -> ( Page.Model, Cmd Page.Msg )
gotFetchMeasuresResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( setError error model, Cmd.none ))
            (\measures ->
                ( LensUtil.set measures .id Page.lenses.measures model
                , measures
                    |> Encode.list encoderMeasure
                    |> Encode.encode 0
                    |> storeMeasures
                )
            )


gotFetchRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipeResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\recipe ->
                model
                    |> Page.lenses.recipeInfo.set (RecipeInfo.from recipe |> Just)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipe).set True
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\recipes ->
                model
                    |> Page.lenses.allRecipes.set (recipes |> List.map (\r -> ( r.id, r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.allRecipes).set True
            )
    , Cmd.none
    )


updateFoods : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateFoods model =
    Decode.decodeString (Decode.list decoderFood)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\foods ->
                ( model
                    |> LensUtil.set
                        foods
                        .id
                        (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foods)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.foods).set
                        (foods
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty foods then
                    Requests.fetchFoods model.authorizedAccess

                  else
                    Cmd.none
                )
            )


updateMeasures : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateMeasures model =
    Decode.decodeString (Decode.list decoderMeasure)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\measures ->
                ( model
                    |> LensUtil.set measures .id Page.lenses.measures
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.measures).set
                        (measures
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty measures then
                    Requests.fetchMeasures model.authorizedAccess

                  else
                    Cmd.none
                )
            )


setFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setFoodsSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.ingredientsGroup
                |> Compose.lensWithLens FoodGroup.lenses.foodsSearchString
        , paginationSettingsLens =
            Page.lenses.ingredientsGroup
                |> Compose.lensWithLens FoodGroup.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.foods
        }
        model
        string
    , Cmd.none
    )


setComplexFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setComplexFoodsSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.complexIngredientsGroup
                |> Compose.lensWithLens FoodGroup.lenses.foodsSearchString
        , paginationSettingsLens =
            Page.lenses.complexIngredientsGroup
                |> Compose.lensWithLens FoodGroup.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.foods
        }
        model
        string
    , Cmd.none
    )


selectFood : Page.Model -> Food -> ( Page.Model, Cmd msg )
selectFood model food =
    ( model
        |> LensUtil.insertAtId food.id
            (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            (IngredientCreationClientInput.default model.recipeId food.id (food.measures |> List.head |> Maybe.Extra.unwrap 0 .id))
    , Cmd.none
    )


selectComplexFood : Page.Model -> ComplexFood -> ( Page.Model, Cmd msg )
selectComplexFood model complexFood =
    ( model
        |> LensUtil.insertAtId complexFood.recipeId
            (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            (ComplexIngredientClientInput.fromFood complexFood)
    , Cmd.none
    )


deselectFood : Page.Model -> FoodId -> ( Page.Model, Cmd Page.Msg )
deselectFood model foodId =
    ( model
        |> LensUtil.deleteAtId foodId (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
    , Cmd.none
    )


deselectComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
deselectComplexFood model complexFoodId =
    ( model
        |> LensUtil.deleteAtId complexFoodId (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
    , Cmd.none
    )


addFood : Page.Model -> FoodId -> ( Page.Model, Cmd Page.Msg )
addFood model foodId =
    ( model
    , model
        |> (Page.lenses.ingredientsGroup
                |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd
                |> Compose.lensWithOptional (LensUtil.dictByKey foodId)
           ).getOption
        |> Maybe.Extra.unwrap Cmd.none
            (IngredientCreationClientInput.toCreation
                >> Requests.addFood model.authorizedAccess
            )
    )


addComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
addComplexFood model complexFoodId =
    ( model
    , model
        |> (Page.lenses.complexIngredientsGroup
                |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd
                |> Compose.lensWithOptional (LensUtil.dictByKey complexFoodId)
           ).getOption
        |> Maybe.Extra.unwrap Cmd.none
            (ComplexIngredientClientInput.to
                >> Requests.addComplexFood model.authorizedAccess model.recipeId
            )
    )


gotAddFoodResponse : Page.Model -> Result Error Ingredient -> ( Page.Model, Cmd Page.Msg )
gotAddFoodResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\ingredient ->
                model
                    |> LensUtil.insertAtId ingredient.id
                        (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.ingredients)
                        (ingredient |> Editing.asView)
                    |> LensUtil.deleteAtId ingredient.foodId
                        (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            )
    , Cmd.none
    )


gotAddComplexFoodResponse : Page.Model -> Result Error ComplexIngredient -> ( Page.Model, Cmd Page.Msg )
gotAddComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexIngredient ->
                model
                    |> LensUtil.insertAtId complexIngredient.complexFoodId
                        (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.ingredients)
                        (complexIngredient |> Editing.asView)
                    |> LensUtil.deleteAtId complexIngredient.complexFoodId
                        (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            )
    , Cmd.none
    )


updateAddFood : Page.Model -> IngredientCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddFood model ingredientCreationClientInput =
    ( model
        |> LensUtil.insertAtId ingredientCreationClientInput.foodId
            (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            ingredientCreationClientInput
    , Cmd.none
    )


updateAddComplexFood : Page.Model -> ComplexIngredientClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddComplexFood model complexIngredientClientInput =
    ( model
        |> LensUtil.insertAtId complexIngredientClientInput.complexFoodId
            (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd)
            complexIngredientClientInput
    , Cmd.none
    )


setIngredientsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setIngredientsPagination model pagination =
    ( model |> (Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.pagination).set pagination
    , Cmd.none
    )


setComplexIngredientsPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setComplexIngredientsPagination model pagination =
    ( model |> (Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.pagination).set pagination
    , Cmd.none
    )


changeFoodsMode : Page.Model -> Page.FoodsMode -> ( Page.Model, Cmd Page.Msg )
changeFoodsMode model foodsMode =
    ( model
        |> Page.lenses.foodsMode.set foodsMode
    , Cmd.none
    )


setIngredientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setIngredientsSearchString =
    setSearchString
        { searchStringLens = Page.lenses.ingredientsSearchString
        , foodGroupLens = Page.lenses.ingredientsGroup
        }


setComplexIngredientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setComplexIngredientsSearchString =
    setSearchString
        { searchStringLens = Page.lenses.complexIngredientsSearchString
        , foodGroupLens = Page.lenses.complexIngredientsGroup
        }


setSearchString :
    { searchStringLens : Lens Page.Model String
    , foodGroupLens : Lens Page.Model (FoodGroup.FoodGroup ingredientId ingredient update foodId food creation)
    }
    -> Page.Model
    -> String
    -> ( Page.Model, Cmd Page.Msg )
setSearchString lenses model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            lenses.searchStringLens
        , paginationSettingsLens =
            lenses.foodGroupLens
                |> Compose.lensWithLens FoodGroup.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.ingredients
        }
        model
        string
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization


setJsonError : Decode.Error -> Page.Model -> Page.Model
setJsonError =
    HttpUtil.setJsonError Page.lenses.initialization