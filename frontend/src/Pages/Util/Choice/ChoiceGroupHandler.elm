module Pages.Util.Choice.ChoiceGroupHandler exposing (updateLogic)

import Api.Auxiliary exposing (RecipeId)
import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.Choice.ChoiceGroup as ChoiceGroup
import Pages.Util.Choice.Pagination as Pagination
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
    , createIngredient : AuthorizedAccess -> RecipeId -> creation -> Cmd (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation)
    , saveIngredient : AuthorizedAccess -> RecipeId -> update -> Cmd (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation)
    , deleteIngredient : AuthorizedAccess -> RecipeId -> ingredientId -> Cmd (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation)
    , storeFoods : List food -> Cmd (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation)
    }
    -> ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation
    -> ChoiceGroup.Model ingredientId ingredient update foodId food creation
    -> ( ChoiceGroup.Model ingredientId ingredient update foodId food creation, Cmd (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation) )
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
                                ChoiceGroup.lenses.main.ingredients
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
                                (ChoiceGroup.lenses.initial.ingredients.set
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
                                (ChoiceGroup.lenses.initial.foods.set
                                    (foods |> DictList.fromListWithKey ps.idOfFood |> Just)
                                )
                        , foods
                            |> ps.storeFoods
                        )
                    )

        toggleFoodControls foodId =
            ( model
                |> Tristate.mapMain (LensUtil.updateById foodId ChoiceGroup.lenses.main.foods Editing.toggleControls)
            , Cmd.none
            )

        selectFood food =
            ( model
                |> Tristate.mapMain
                    (\main ->
                        main
                            |> LensUtil.updateById (food |> ps.idOfFood)
                                ChoiceGroup.lenses.main.foods
                                (Editing.toUpdate (flip ps.toCreation main.recipeId))
                    )
            , Cmd.none
            )

        deselectFood foodId =
            ( model
                |> Tristate.mapMain
                    (LensUtil.updateById foodId
                        ChoiceGroup.lenses.main.foods
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
                            |> (ChoiceGroup.lenses.main.foods
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
                                    ChoiceGroup.lenses.main.ingredients
                                    (ingredient |> Editing.asView)
                                    >> LensUtil.updateById (ingredient |> ps.foodIdOfIngredient)
                                        ChoiceGroup.lenses.main.foods
                                        Editing.toView
                                )
                    )
            , Cmd.none
            )

        updateCreation ingredientCreationClientInput =
            ( model
                |> Tristate.mapMain
                    (LensUtil.updateById (ingredientCreationClientInput |> ps.foodIdOfCreation)
                        ChoiceGroup.lenses.main.foods
                        (Editing.lenses.update.set ingredientCreationClientInput)
                    )
            , Cmd.none
            )

        setIngredientsPagination pagination =
            ( model
                |> Tristate.mapMain (ChoiceGroup.lenses.main.pagination.set pagination)
            , Cmd.none
            )

        setIngredientsSearchString string =
            ( model
                |> Tristate.mapMain
                    (PaginationSettings.setSearchStringAndReset
                        { searchStringLens =
                            ChoiceGroup.lenses.main.ingredientsSearchString
                        , paginationSettingsLens =
                            ChoiceGroup.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.ingredients
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
                            ChoiceGroup.lenses.main.foodsSearchString
                        , paginationSettingsLens =
                            ChoiceGroup.lenses.main.pagination
                                |> Compose.lensWithLens Pagination.lenses.foods
                        }
                        string
                    )
            , Cmd.none
            )
    in
    case msg of
        ChoiceGroup.Edit update ->
            edit update

        ChoiceGroup.SaveEdit update ->
            saveEdit update

        ChoiceGroup.GotSaveEditResponse result ->
            gotSaveEditResponse result

        ChoiceGroup.ToggleControls ingredientId ->
            toggleControls ingredientId

        ChoiceGroup.EnterEdit ingredientId ->
            enterEdit ingredientId

        ChoiceGroup.ExitEdit ingredientId ->
            exitEdit ingredientId

        ChoiceGroup.RequestDelete ingredientId ->
            requestDelete ingredientId

        ChoiceGroup.ConfirmDelete ingredientId ->
            confirmDelete ingredientId

        ChoiceGroup.CancelDelete ingredientId ->
            cancelDelete ingredientId

        ChoiceGroup.GotDeleteResponse ingredientId result ->
            gotDeleteResponse ingredientId result

        ChoiceGroup.GotFetchResponse result ->
            gotFetchResponse result

        ChoiceGroup.GotFetchFoodsResponse result ->
            gotFetchFoodsResponse result

        ChoiceGroup.ToggleFoodControls foodId ->
            toggleFoodControls foodId

        ChoiceGroup.SelectFood food ->
            selectFood food

        ChoiceGroup.DeselectFood foodId ->
            deselectFood foodId

        ChoiceGroup.Create foodId ->
            create foodId

        ChoiceGroup.GotCreateResponse result ->
            gotCreateResponse result

        ChoiceGroup.UpdateCreation creation ->
            updateCreation creation

        ChoiceGroup.SetIngredientsPagination pagination ->
            setIngredientsPagination pagination

        ChoiceGroup.SetIngredientsSearchString string ->
            setIngredientsSearchString string

        ChoiceGroup.SetFoodsSearchString string ->
            setFoodsSearchString string


mapIngredientStateById :
    ingredientId
    -> (ChoiceGroup.IngredientState ingredient update -> ChoiceGroup.IngredientState ingredient update)
    -> ChoiceGroup.Model ingredientId ingredient update foodId food creation
    -> ChoiceGroup.Model ingredientId ingredient update foodId food creation
mapIngredientStateById ingredientId =
    (ChoiceGroup.lenses.main.ingredients
        |> LensUtil.updateById ingredientId
    )
        >> Tristate.mapMain
