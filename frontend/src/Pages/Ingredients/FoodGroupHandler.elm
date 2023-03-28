module Pages.Ingredients.FoodGroupHandler exposing (updateLogic)

import Api.Auxiliary exposing (RecipeId)
import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.FoodGroup as FoodGroup
import Pages.Ingredients.Pagination as Pagination
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing
import Util.LensUtil as LensUtil


updateLogic :
    { idOfIngredient : ingredient -> ingredientId
    , idOfUpdate : update -> ingredientId
    , idOfFood : food -> foodId
    , foodIdOfIngredient : ingredient -> foodId
    , foodIdOfCreation : creation -> foodId
    , toUpdate : ingredient -> update
    , toCreation : food -> RecipeId -> creation
    , createIngredient : AuthorizedAccess -> RecipeId -> creation -> Cmd (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation)
    , saveIngredient : AuthorizedAccess -> RecipeId -> update -> Cmd (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation)
    , deleteIngredient : AuthorizedAccess -> RecipeId -> ingredientId -> Cmd (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation)
    , storeFoods : List food -> Cmd (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation)
    }
    -> FoodGroup.LogicMsg ingredientId ingredient update foodId food creation
    -> FoodGroup.Model ingredientId ingredient update foodId food creation
    -> ( FoodGroup.Model ingredientId ingredient update foodId food creation, Cmd (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation) )
updateLogic ps msg model =
    let
        edit update =
            ( model
                |> mapIngredientStateById (update |> ps.idOfUpdate)
                    (Editing.lenses.update.set update)
            , Cmd.none
            )

        saveEdit ingredientUpdateClientInput =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ingredientUpdateClientInput
                            |> ps.saveIngredient
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                                main.recipeId
                    )
            )

        gotSaveEditResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\ingredient ->
                        model
                            |> mapIngredientStateById (ingredient |> ps.idOfIngredient)
                                (Editing.asViewWithElement ingredient)
                    )
            , Cmd.none
            )

        toggleControls ingredientId =
            ( model
                |> mapIngredientStateById ingredientId Editing.toggleControls
            , Cmd.none
            )

        enterEdit ingredientId =
            ( model
                |> mapIngredientStateById ingredientId (Editing.toUpdate ps.toUpdate)
            , Cmd.none
            )

        exitEdit ingredientId =
            ( model
                |> mapIngredientStateById ingredientId Editing.toView
            , Cmd.none
            )

        requestDelete ingredientId =
            ( model
                |> mapIngredientStateById ingredientId Editing.toDelete
            , Cmd.none
            )

        confirmDelete ingredientId =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ps.deleteIngredient
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            main.recipeId
                            ingredientId
                    )
            )

        cancelDelete ingredientId =
            ( model
                |> mapIngredientStateById ingredientId Editing.toView
            , Cmd.none
            )

        gotDeleteResponse ingredientId result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (model
                        |> Tristate.mapMain
                            (LensUtil.deleteAtId ingredientId
                                FoodGroup.lenses.main.ingredients
                            )
                        |> always
                    )
            , Cmd.none
            )

        gotFetchResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\ingredients ->
                        model
                            |> Tristate.mapInitial
                                (FoodGroup.lenses.initial.ingredients.set
                                    (ingredients
                                        |> List.map Editing.asView
                                        |> DictList.fromListWithKey (.original >> ps.idOfIngredient)
                                        |> Just
                                    )
                                )
                    )
            , Cmd.none
            )

        gotFetchFoodsResponse result =
            result
                |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
                    (\foods ->
                        ( model
                            |> Tristate.mapInitial
                                (FoodGroup.lenses.initial.foods.set
                                    (foods |> DictList.fromListWithKey ps.idOfFood |> Just)
                                )
                        , foods
                            |> ps.storeFoods
                        )
                    )

        selectFood food =
            ( model
                |> Tristate.mapMain
                    (\main ->
                        main
                            |> LensUtil.updateById (food |> ps.idOfFood)
                                FoodGroup.lenses.main.foods
                                (Editing.toUpdate (flip ps.toCreation main.recipeId))
                    )
            , Cmd.none
            )

        deselectFood foodId =
            ( model
                |> Tristate.mapMain
                    (LensUtil.updateById foodId
                        FoodGroup.lenses.main.foods
                        Editing.toView
                    )
            , Cmd.none
            )

        create foodId =
            ( model
            , model
                |> Tristate.lenses.main.getOption
                |> Maybe.andThen
                    (\main ->
                        main
                            |> (FoodGroup.lenses.main.foods
                                    |> Compose.lensWithOptional (LensUtil.dictByKey foodId)
                                    |> Compose.optionalWithOptional Editing.lenses.update
                               ).getOption
                            |> Maybe.map
                                (ps.createIngredient
                                    { configuration = model.configuration
                                    , jwt = main.jwt
                                    }
                                    main.recipeId
                                )
                    )
                |> Maybe.withDefault Cmd.none
            )

        gotCreateResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\ingredient ->
                        model
                            |> Tristate.mapMain
                                (LensUtil.insertAtId (ingredient |> ps.idOfIngredient)
                                    FoodGroup.lenses.main.ingredients
                                    (ingredient |> Editing.asView)
                                    >> LensUtil.updateById (ingredient |> ps.foodIdOfIngredient)
                                        FoodGroup.lenses.main.foods
                                        Editing.toView
                                )
                    )
            , Cmd.none
            )

        updateCreation ingredientCreationClientInput =
            ( model
                |> Tristate.mapMain
                    (LensUtil.updateById (ingredientCreationClientInput |> ps.foodIdOfCreation)
                        FoodGroup.lenses.main.foods
                        (Editing.lenses.update.set ingredientCreationClientInput)
                    )
            , Cmd.none
            )

        setIngredientsPagination pagination =
            ( model
                |> Tristate.mapMain (FoodGroup.lenses.main.pagination.set pagination)
            , Cmd.none
            )

        setIngredientsSearchString string =
            ( model
                |> Tristate.mapMain
                    (PaginationSettings.setSearchStringAndReset
                        { searchStringLens =
                            FoodGroup.lenses.main.ingredientsSearchString
                        , paginationSettingsLens =
                            FoodGroup.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.ingredients
                        }
                        string
                    )
            , Cmd.none
            )

        setFoodsSearchString string =
            ( model
                |> Tristate.mapMain
                    (PaginationSettings.setSearchStringAndReset
                        { searchStringLens =
                            FoodGroup.lenses.main.foodsSearchString
                        , paginationSettingsLens =
                            FoodGroup.lenses.main.pagination
                                |> Compose.lensWithLens Pagination.lenses.foods
                        }
                        string
                    )
            , Cmd.none
            )
    in
    case msg of
        FoodGroup.Edit update ->
            edit update

        FoodGroup.SaveEdit update ->
            saveEdit update

        FoodGroup.GotSaveEditResponse result ->
            gotSaveEditResponse result

        FoodGroup.ToggleControls ingredientId ->
            toggleControls ingredientId

        FoodGroup.EnterEdit ingredientId ->
            enterEdit ingredientId

        FoodGroup.ExitEdit ingredientId ->
            exitEdit ingredientId

        FoodGroup.RequestDelete ingredientId ->
            requestDelete ingredientId

        FoodGroup.ConfirmDelete ingredientId ->
            confirmDelete ingredientId

        FoodGroup.CancelDelete ingredientId ->
            cancelDelete ingredientId

        FoodGroup.GotDeleteResponse ingredientId result ->
            gotDeleteResponse ingredientId result

        FoodGroup.GotFetchResponse result ->
            gotFetchResponse result

        FoodGroup.GotFetchFoodsResponse result ->
            gotFetchFoodsResponse result

        FoodGroup.SelectFood food ->
            selectFood food

        FoodGroup.DeselectFood foodId ->
            deselectFood foodId

        FoodGroup.Create foodId ->
            create foodId

        FoodGroup.GotCreateResponse result ->
            gotCreateResponse result

        FoodGroup.UpdateCreation creation ->
            updateCreation creation

        FoodGroup.SetIngredientsPagination pagination ->
            setIngredientsPagination pagination

        FoodGroup.SetIngredientsSearchString string ->
            setIngredientsSearchString string

        FoodGroup.SetFoodsSearchString string ->
            setFoodsSearchString string


mapIngredientStateById :
    ingredientId
    -> (FoodGroup.IngredientState ingredient update -> FoodGroup.IngredientState ingredient update)
    -> FoodGroup.Model ingredientId ingredient update foodId food creation
    -> FoodGroup.Model ingredientId ingredient update foodId food creation
mapIngredientStateById ingredientId =
    (FoodGroup.lenses.main.ingredients
        |> LensUtil.updateById ingredientId
    )
        >> Tristate.mapMain
