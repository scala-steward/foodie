module Pages.Ingredients.View exposing (view)

import Addresses.Frontend
import Api.Auxiliary exposing (ComplexFoodId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.AmountUnit exposing (AmountUnit)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dropdown exposing (Item, dropdown)
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.AmountUnitClientInput as AmountUnitClientInput
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup exposing (IngredientState)
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Page as Page
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Pages.Ingredients.Plain.View
import Pages.Ingredients.Recipe.View
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput
import Pages.Recipes.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate exposing (PaginatedList)
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        main
    <|
        let
            viewComplexIngredientState =
                Editing.unpack
                    { onView = \o b -> viewComplexIngredientLine configuration main.complexIngredientsGroup.foods o
                    , onUpdate = updateComplexIngredientLine main.complexIngredientsGroup.foods
                    , onDelete = deleteComplexIngredientLine main.complexIngredientsGroup.foods
                    }

            viewIngredientsWith :
                (IngredientState ingredient update -> Bool)
                -> Lens Page.Main (FoodGroup.Main ingredientId ingredient update foodId food creation)
                -> (ingredient -> String)
                -> PaginatedList (IngredientState ingredient update)
            viewIngredientsWith searchFilter groupLens nameOf =
                main
                    |> groupLens.get
                    |> .ingredients
                    |> DictList.values
                    |> List.filter searchFilter
                    |> List.sortBy (.original >> nameOf >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination =
                            groupLens
                                |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                                |> Compose.lensWithLens Pagination.lenses.ingredients
                        }
                        main

            -- todo: Remove duplication!
            viewComplexIngredients =
                viewIngredientsWith
                    (.original
                        >> .complexFoodId
                        >> flip DictList.get main.complexIngredientsGroup.foods
                        >> Maybe.Extra.unwrap "" (.original >> .name)
                        >> SearchUtil.search main.complexIngredientsSearchString
                    )
                    Page.lenses.main.complexIngredientsGroup
                    (.complexFoodId
                        >> flip DictList.get main.complexIngredientsGroup.foods
                        >> Maybe.Extra.unwrap "" (.original >> .name)
                    )
        in
        div [ Style.ids.ingredientEditor ]
            [ div []
                [ Pages.Ingredients.Recipe.View.viewMain configuration main.recipe
                    |> Html.map Page.RecipeMsg
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Ingredients" ] ]
            , Pages.Ingredients.Plain.View.viewMain main.ingredientsGroup |> Html.map Page.IngredientMsg
            , div [ Style.classes.elements ] [ label [] [ text "Complex ingredients" ] ]
            , div [ Style.classes.choices ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetComplexIngredientsSearchString
                    , searchString = main.complexIngredientsSearchString
                    }
                , table [ Style.classes.elementsWithControlsTable, Style.classes.ingredientEditTable ]
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [] [ label [] [ text "Name" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Factor" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
                            , th [ Style.classes.toggle ] []
                            ]
                        ]
                    , tbody []
                        (viewComplexIngredients
                            |> Paginate.page
                            |> List.map viewComplexIngredientState
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                                , items = Pagination.lenses.ingredients
                                }
                                main
                                >> Page.SetComplexIngredientsPagination
                        , elements = viewComplexIngredients
                        }
                    ]
                ]
            , div []
                [ button
                    [ disabled <| main.foodsMode == Page.Plain
                    , onClick <| Page.ChangeFoodsMode Page.Plain
                    , Style.classes.button.alternative
                    ]
                    [ text "Ingredients" ]
                , button
                    [ disabled <| main.foodsMode == Page.Complex
                    , onClick <| Page.ChangeFoodsMode Page.Complex
                    , Style.classes.button.alternative
                    ]
                    [ text "Complex ingredients" ]
                ]
            , case main.foodsMode of
                Page.Plain ->
                    Pages.Ingredients.Plain.View.viewFoods configuration main

                Page.Complex ->
                    viewComplex configuration main
            ]


viewComplex : Configuration -> Page.Main -> Html Page.LogicMsg
viewComplex configuration main =
    let
        viewComplexFoods =
            main.complexIngredientsGroup.foods
                |> DictList.values
                |> List.filter (.original >> .name >> SearchUtil.search main.complexIngredientsGroup.foodsSearchString)
                |> List.sortBy (.original >> .name)
                |> ViewUtil.paginate
                    { pagination =
                        Page.lenses.main.complexIngredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.foods
                    }
                    main

        ( amount, unit ) =
            if anySelection Page.lenses.main.complexIngredientsGroup main then
                ( "Factor", "Amount" )

            else
                ( "", "" )
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = Page.SetComplexFoodsSearchString
                , searchString = main.complexIngredientsGroup.foodsSearchString
                }
            , table [ Style.classes.elementsWithControlsTable ]
                [ colgroup []
                    [ col [] []
                    , col [] []
                    , col [] []
                    , col [ stringProperty "span" "3" ] []
                    ]
                , thead []
                    [ tr [ Style.classes.tableHeader ]
                        [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                        , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text amount ] ]
                        , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text unit ] ]
                        , th [ colspan 3, scope "colgroup", Style.classes.controlsGroup ] []
                        ]
                    ]
                , tbody []
                    (viewComplexFoods
                        |> Paginate.page
                        |> List.map (viewComplexFoodLine configuration main.complexIngredientsGroup.ingredients)
                    )
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.main.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.main.pagination
                            , items = Pagination.lenses.foods
                            }
                            main
                            >> Page.SetComplexIngredientsPagination
                    , elements = viewComplexFoods
                    }
                ]
            ]
        ]


viewComplexIngredientLine : Configuration -> Page.ComplexFoodMap -> ComplexIngredient -> Html Page.LogicMsg
viewComplexIngredientLine configuration complexFoodMap complexIngredient =
    let
        editMsg =
            Page.EnterEditComplexIngredient complexIngredient.complexFoodId |> onClick
    in
    complexIngredientLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteComplexIngredient complexIngredient.complexFoodId) ] [ text "Delete" ] ]
            , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexIngredient.complexFoodId ]
            ]
        , onClick = [ editMsg ]
        , complexFoodMap = complexFoodMap
        }
        complexIngredient


deleteComplexIngredientLine : Page.ComplexFoodMap -> ComplexIngredient -> Html Page.LogicMsg
deleteComplexIngredientLine complexFoodMap complexIngredient =
    complexIngredientLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteComplexIngredient complexIngredient.complexFoodId) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteComplexIngredient complexIngredient.complexFoodId) ] [ text "Cancel" ] ]
            ]
        , onClick = []
        , complexFoodMap = complexFoodMap
        }
        complexIngredient


complexIngredientLineWith :
    { controls : List (Html Page.LogicMsg)
    , onClick : List (Attribute Page.LogicMsg)
    , complexFoodMap : Page.ComplexFoodMap
    }
    -> ComplexIngredient
    -> Html Page.LogicMsg
complexIngredientLineWith ps complexIngredient =
    let
        withOnClick =
            (++) ps.onClick

        --todo: Flatten maybe uses
        complexFood =
            DictList.get complexIngredient.complexFoodId ps.complexFoodMap |> Maybe.map .original

        amountInfo =
            complexFood
                |> Maybe.Extra.unwrap ""
                    (\cf ->
                        String.concat
                            [ cf.amountGrams |> String.fromFloat
                            , "g"
                            , Maybe.Extra.unwrap ""
                                (\amountMillilitres -> String.concat [ " = ", amountMillilitres |> String.fromFloat, "ml" ])
                                cf.amountMilliLitres
                            ]
                    )
    in
    tr [ Style.classes.editing ]
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| String.fromFloat <| complexIngredient.factor ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| amountInfo ] ]
         ]
            ++ ps.controls
        )


updateComplexIngredientLine : Page.ComplexFoodMap -> ComplexIngredient -> ComplexIngredientClientInput -> Html Page.LogicMsg
updateComplexIngredientLine complexFoodMap complexIngredient complexIngredientUpdateClientInput =
    let
        saveMsg =
            Page.SaveComplexIngredientEdit complexIngredientUpdateClientInput

        cancelMsg =
            Page.ExitEditComplexIngredientAt complexIngredient.complexFoodId

        -- todo: Flatten maybes
        complexFood =
            DictList.get complexIngredient.complexFoodId complexFoodMap |> Maybe.map .original
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    complexIngredientUpdateClientInput.factor.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ComplexIngredientClientInput.lenses.factor
                        ).set
                        complexIngredientUpdateClientInput
                        >> Page.UpdateComplexIngredient
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
            [ label [ Style.classes.editable, Style.classes.numberLabel ] [ text <| Maybe.Extra.unwrap "" amountInfoOf <| complexFood ]
            ]
        , td []
            [ button [ Style.classes.button.confirm, onClick saveMsg ]
                [ text "Save" ]
            ]
        , td []
            [ button [ Style.classes.button.cancel, onClick cancelMsg ]
                [ text "Cancel" ]
            ]
        ]


type alias ComplexFoodInfo =
    { name : String
    , amountGrams : String
    , amountMilliLitres : Maybe String
    }


amountInfoOf : ComplexFood -> String
amountInfoOf complexFood =
    let
        suffix =
            Maybe.Extra.unwrap ""
                (\amountMillilitres -> String.concat [ " = ", amountMillilitres |> String.fromFloat ])
                complexFood.amountMilliLitres
    in
    (complexFood.amountGrams |> String.fromFloat) ++ suffix


viewComplexFoodLine : Configuration -> Page.ComplexIngredientStateMap -> Editing ComplexFood ComplexIngredientClientInput -> Html Page.LogicMsg
viewComplexFoodLine configuration complexIngredients complexFood =
    let
        addMsg =
            Page.AddComplexFood complexFood.original.recipeId

        selectMsg =
            Page.SelectComplexFood complexFood.original

        cancelMsg =
            Page.DeselectComplexFood complexFood.original.recipeId

        maybeComplexIngredientToAdd =
            complexFood
                |> Editing.unpack
                    { onView = \_ _ -> Nothing
                    , onUpdate = \_ u -> Just u
                    , onDelete = \_ -> Nothing
                    }

        rowClickAction =
            if Maybe.Extra.isJust maybeComplexIngredientToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeComplexIngredientToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexFood.original.recipeId ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton configuration complexFood.original.recipeId ]
                    ]

                Just complexIngredientToAdd ->
                    let
                        exists =
                            DictListUtil.existsValue (\complexIngredient -> complexIngredient.original.complexFoodId == complexIngredientToAdd.complexFoodId) complexIngredients

                        validInput =
                            List.all identity
                                [ complexIngredientToAdd.factor |> ValidatedInput.isValid
                                , exists |> not
                                ]

                        ( confirmName, confirmStyle ) =
                            if exists then
                                ( "Added", Style.classes.button.edit )

                            else
                                ( "Add", Style.classes.button.confirm )
                    in
                    [ td [ Style.classes.numberCell ]
                        ([ input
                            [ value complexIngredientToAdd.factor.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexIngredientClientInput.lenses.factor
                                    ).set
                                    complexIngredientToAdd
                                    >> Page.UpdateAddComplexFood
                                )
                            , Style.classes.numberLabel
                            , HtmlUtil.onEscape cancelMsg
                            , onEnter addMsg
                            ]
                            []
                         ]
                            |> List.filter (exists |> not |> always)
                        )
                    , td [ Style.classes.editable, Style.classes.numberLabel, onClick selectMsg ] [ label [] [ text <| amountInfoOf <| complexFood.original ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| confirmStyle
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick addMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text confirmName
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick cancelMsg ] [ text "Cancel" ] ]
                    ]
    in
    tr ([ Style.classes.editing ] ++ rowClickAction)
        (td [ Style.classes.editable ] [ label [] [ text complexFood.original.name ] ]
            :: process
        )


anySelection : Lens Page.Main (FoodGroup.Main ingredientId ingredient update foodId food creation) -> Page.Main -> Bool
anySelection foodGroupLens =
    (foodGroupLens |> Compose.lensWithLens FoodGroup.lenses.main.foods).get
        >> DictListUtil.existsValue Editing.isUpdate
