module Pages.ComplexFoods.View exposing (..)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.ComplexFoods.Pagination as Pagination
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate as Paginate exposing (PaginatedList)
import Util.DictList as DictList
import Util.Editing as Editing
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
        , currentPage = Just ViewUtil.ComplexFoods
        , showNavigation = True
        }
        main
    <|
        let
            viewComplexFoodState =
                Editing.unpack
                    { onView = viewComplexFoodLine main.recipes
                    , onUpdate = updateComplexFoodLine
                    , onDelete = deleteComplexFoodLine main.recipes
                    }

            viewComplexFoods =
                main.complexFoods
                    |> DictList.values
                    |> List.filter (\complexFood -> SearchUtil.search main.complexFoodsSearchString complexFood.original.name)
                    |> List.sortBy (.original >> .name >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.complexFoods
                        }
                        main

            viewRecipes =
                main.recipes
                    |> DictList.values
                    |> List.filter (.name >> SearchUtil.search main.recipesSearchString)
                    |> List.sortBy .name
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.recipes
                        }
                        main

            anySelection =
                main.complexFoodsToCreate
                    |> DictList.isEmpty
                    |> not

            ( amountGrams, amountMillilitres ) =
                if anySelection then
                    ( "Amount in g", "Amount in ml" )

                else
                    ( "", "" )
        in
        div [ Style.ids.complexFoodEditor ]
            [ div [ Style.classes.elements ] [ label [] [ text "Complex foods" ] ]
            , div [ Style.classes.choices ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetComplexFoodsSearchString
                    , searchString = main.complexFoodsSearchString
                    }
                , table [ Style.classes.elementsWithControlsTable ]
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Amount in g" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Amount in ml" ] ]
                            , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        (viewComplexFoods
                            |> Paginate.page
                            |> List.map viewComplexFoodState
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.main.pagination
                                , items = Pagination.lenses.complexFoods
                                }
                                main
                                >> Page.SetPagination
                        , elements = viewComplexFoods
                        }
                    ]
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetRecipesSearchString
                        , searchString = main.recipesSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text amountGrams ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text amountMillilitres ] ]
                                , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeLine main.complexFoodsToCreate main.complexFoods)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.recipes
                                    }
                                    main
                                    >> Page.SetPagination
                            , elements = viewRecipes
                            }
                        ]
                    ]
                ]
            ]


viewComplexFoodLine : Page.RecipeMap -> ComplexFood -> Html Page.LogicMsg
viewComplexFoodLine recipeMap complexFood =
    let
        editMsg =
            Page.EnterEditComplexFood complexFood.recipeId |> onClick
    in
    complexFoodLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteComplexFood complexFood.recipeId) ] [ text "Delete" ] ]
            ]
        , onClick = [ editMsg ]
        , recipeMap = recipeMap
        }
        complexFood


deleteComplexFoodLine : Page.RecipeMap -> ComplexFood -> Html Page.LogicMsg
deleteComplexFoodLine recipeMap complexFood =
    complexFoodLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteComplexFood complexFood.recipeId) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteComplexFood complexFood.recipeId) ] [ text "Cancel" ] ]
            ]
        , onClick = []
        , recipeMap = recipeMap
        }
        complexFood


complexFoodLineWith :
    { controls : List (Html Page.LogicMsg)
    , onClick : List (Attribute Page.LogicMsg)
    , recipeMap : Page.RecipeMap
    }
    -> ComplexFood
    -> Html Page.LogicMsg
complexFoodLineWith ps complexFood =
    let
        withOnClick =
            (++) ps.onClick
    in
    tr [ Style.classes.editing ]
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| .name <| complexFood ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| String.fromFloat <| complexFood.amountGrams ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| Maybe.Extra.unwrap "" String.fromFloat <| complexFood.amountMilliLitres ] ]
         ]
            ++ ps.controls
        )


updateComplexFoodLine : ComplexFood -> ComplexFoodClientInput -> Html Page.LogicMsg
updateComplexFoodLine complexFood complexFoodClientInput =
    let
        saveMsg =
            Page.SaveComplexFoodEdit complexFoodClientInput

        cancelMsg =
            Page.ExitEditComplexFood complexFood.recipeId
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| .name <| complexFood ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    complexFoodClientInput.amountGrams.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ComplexFoodClientInput.lenses.amountGrams
                        ).set
                        complexFoodClientInput
                        >> Page.UpdateComplexFood
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    complexFoodClientInput.amountMilliLitres.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ComplexFoodClientInput.lenses.amountMilliLitres
                        ).set
                        complexFoodClientInput
                        >> Page.UpdateComplexFood
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
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


viewRecipeLine : Page.CreateComplexFoodsMap -> Page.ComplexFoodStateMap -> Recipe -> Html Page.LogicMsg
viewRecipeLine complexFoodsToCreate complexFoods recipe =
    let
        createMsg =
            Page.CreateComplexFood recipe.id

        selectMsg =
            Page.SelectRecipe recipe

        cancelMsg =
            Page.DeselectRecipe recipe.id

        maybeComplexFoodToAdd =
            DictList.get recipe.id complexFoodsToCreate

        rowClickAction =
            if Maybe.Extra.isJust maybeComplexFoodToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeComplexFoodToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just complexFoodToAdd ->
                    let
                        exists =
                            DictListUtil.existsValue (\complexFood -> complexFood.original.recipeId == complexFoodToAdd.recipeId) complexFoods

                        validInput =
                            List.all identity
                                [ complexFoodToAdd.amountGrams |> ValidatedInput.isValid
                                , complexFoodToAdd.amountMilliLitres |> ValidatedInput.isValid
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
                            ([ MaybeUtil.defined <| value complexFoodToAdd.amountGrams.text
                             , MaybeUtil.defined <|
                                onInput <|
                                    flip
                                        (ValidatedInput.lift
                                            ComplexFoodClientInput.lenses.amountGrams
                                        ).set
                                        complexFoodToAdd
                                        >> Page.UpdateComplexFoodCreation
                             , MaybeUtil.defined <| Style.classes.numberLabel
                             , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                             , MaybeUtil.optional validInput <| onEnter createMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            []
                         ]
                            |> List.filter (exists |> not |> always)
                        )
                    , td [ Style.classes.numberCell ]
                        ([ input
                            ([ MaybeUtil.defined <| value complexFoodToAdd.amountMilliLitres.text
                             , MaybeUtil.defined <|
                                onInput <|
                                    flip
                                        (ValidatedInput.lift
                                            ComplexFoodClientInput.lenses.amountMilliLitres
                                        ).set
                                        complexFoodToAdd
                                        >> Page.UpdateComplexFoodCreation
                             , MaybeUtil.defined <| Style.classes.numberLabel
                             , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                             , MaybeUtil.optional validInput <| onEnter createMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            []
                         ]
                            |> List.filter (exists |> not |> always)
                        )
                    , td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| confirmStyle
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick createMsg
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
        (td [ Style.classes.editable ] [ label [] [ text recipe.name ] ]
            :: process
        )
