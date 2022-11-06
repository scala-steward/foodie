module Pages.MealEntries.View exposing (view)

import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Page as Page exposing (RecipeMap)
import Pages.MealEntries.Pagination as Pagination
import Pages.MealEntries.Status as Status
import Pages.Util.DateUtil as DateUtil
import Pages.Util.DictUtil as DictUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        model
    <|
        let
            viewMealEntryState =
                Editing.unpack
                    { onView = viewMealEntryLine model.recipes
                    , onUpdate = updateEntryLine model.recipes
                    , onDelete = deleteMealEntryLine model.recipes
                    }

            viewMealEntries =
                model.mealEntries
                    |> Dict.filter (\_ v -> SearchUtil.search model.entriesSearchString (DictUtil.nameOrEmpty model.recipes v.original.recipeId))
                    |> Dict.values
                    |> List.sortBy (.original >> .recipeId >> DictUtil.nameOrEmpty model.recipes >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.mealEntries
                        }
                        model

            viewRecipes =
                model.recipes
                    |> Dict.filter (\_ v -> SearchUtil.search model.recipesSearchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.recipes
                        }
                        model

            anySelection =
                model.mealEntriesToAdd
                    |> Dict.isEmpty
                    |> not

            numberOfServings =
                if anySelection then
                    "Servings"

                else
                    ""
        in
        div [ Style.ids.mealEntryEditor ]
            [ div []
                [ table [ Style.classes.info ]
                    [ tr []
                        [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Date" ] ]
                        , td [] [ label [] [ text <| Maybe.Extra.unwrap "" (.date >> DateUtil.toString) <| model.mealInfo ] ]
                        ]
                    , tr []
                        [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .name <| model.mealInfo ] ]
                        ]
                    ]
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Dishes" ] ]
            , div [ Style.classes.choices ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetEntriesSearchString
                    , searchString = model.entriesSearchString
                    }
                , table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr []
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col" ] [ label [] [ text "Description" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
                            , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        (viewMealEntries
                            |> Paginate.page
                            |> List.map viewMealEntryState
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.pagination
                                , items = Pagination.lenses.mealEntries
                                }
                                model
                                >> Page.SetPagination
                        , elements = viewMealEntries
                        }
                    ]
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetRecipesSearchString
                        , searchString = model.recipesSearchString
                        }
                    , table [ Style.classes.choiceTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col" ] [ label [] [ text "Description" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text numberOfServings ] ]
                                , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeLine model.mealEntriesToAdd model.mealEntries)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.recipes
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewRecipes
                            }
                        ]
                    ]
                ]
            ]


viewMealEntryLine : Page.RecipeMap -> MealEntry -> Html Page.Msg
viewMealEntryLine recipeMap mealEntry =
    let
        editMsg =
            Page.EnterEditMealEntry mealEntry.id |> onClick
    in
    mealEntryLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteMealEntry mealEntry.id) ] [ text "Delete" ] ]
            ]
        , onClick = [ editMsg ]
        , recipeMap = recipeMap
        }
        mealEntry


deleteMealEntryLine : Page.RecipeMap -> MealEntry -> Html Page.Msg
deleteMealEntryLine recipeMap mealEntry =
    mealEntryLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteMealEntry mealEntry.id) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteMealEntry mealEntry.id) ] [ text "Cancel" ] ]
            ]
        , onClick = []
        , recipeMap = recipeMap
        }
        mealEntry


mealEntryLineWith :
    { controls : List (Html Page.Msg)
    , onClick : List (Attribute Page.Msg)
    , recipeMap : Page.RecipeMap
    }
    -> MealEntry
    -> Html Page.Msg
mealEntryLineWith ps mealEntry =
    let
        withOnClick =
            (++) ps.onClick
    in
    tr [ Style.classes.editing ]
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| DictUtil.nameOrEmpty ps.recipeMap <| mealEntry.recipeId ] ]
         , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Page.descriptionOrEmpty ps.recipeMap <| mealEntry.recipeId ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| String.fromFloat <| mealEntry.numberOfServings ] ]
         ]
            ++ ps.controls
        )


updateEntryLine : Page.RecipeMap -> MealEntry -> MealEntryUpdateClientInput -> Html Page.Msg
updateEntryLine recipeMap mealEntry mealEntryUpdateClientInput =
    let
        saveMsg =
            Page.SaveMealEntryEdit mealEntryUpdateClientInput

        cancelMsg =
            Page.ExitEditMealEntryAt mealEntry.id
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| DictUtil.nameOrEmpty recipeMap <| mealEntry.recipeId ] ]
        , td [] [ label [] [ text <| Page.descriptionOrEmpty recipeMap <| mealEntry.recipeId ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    mealEntryUpdateClientInput.numberOfServings.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            MealEntryUpdateClientInput.lenses.numberOfServings
                        ).set
                        mealEntryUpdateClientInput
                        >> Page.UpdateMealEntry
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


viewRecipeLine : Page.AddMealEntriesMap -> Page.MealEntryStateMap -> Recipe -> Html Page.Msg
viewRecipeLine mealEntriesToAdd mealEntries recipe =
    let
        addMsg =
            Page.AddRecipe recipe.id

        selectMsg =
            Page.SelectRecipe recipe.id

        maybeRecipeToAdd =
            Dict.get recipe.id mealEntriesToAdd

        rowClickAction =
            if Maybe.Extra.isJust maybeRecipeToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeRecipeToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just mealEntryToAdd ->
                    let
                        validInput =
                            mealEntryToAdd.numberOfServings |> ValidatedInput.isValid

                        ( confirmName, confirmMsg, confirmStyle ) =
                            case DictUtil.firstSuch (\mealEntry -> mealEntry.original.recipeId == mealEntryToAdd.recipeId) mealEntries of
                                Nothing ->
                                    ( "Add", addMsg, Style.classes.button.confirm )

                                Just mealEntryOrUpdate ->
                                    ( "Update"
                                    , mealEntryOrUpdate
                                        |> .original
                                        |> MealEntryUpdateClientInput.from
                                        |> MealEntryUpdateClientInput.lenses.numberOfServings.set mealEntryToAdd.numberOfServings
                                        |> Page.SaveMealEntryEdit
                                    , Style.classes.button.edit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            ([ value mealEntryToAdd.numberOfServings.text
                             , onInput
                                (flip
                                    (ValidatedInput.lift
                                        MealEntryCreationClientInput.lenses.numberOfServings
                                    ).set
                                    mealEntryToAdd
                                    >> Page.UpdateAddRecipe
                                )
                             , Style.classes.numberLabel
                             ]
                                ++ (if validInput then
                                        [ onEnter confirmMsg ]

                                    else
                                        []
                                   )
                            )
                            []
                        ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ confirmStyle
                            , disabled <|
                                not <|
                                    validInput
                            , onClick confirmMsg
                            ]
                            [ text confirmName ]
                        ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.cancel, onClick (Page.DeselectRecipe recipe.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr ([ Style.classes.editing ] ++ rowClickAction)
        (td [] [ label [] [ text recipe.name ] ]
            :: td [] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
            :: process
        )
