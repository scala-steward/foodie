module Pages.MealEntries.View exposing (view)

import Addresses.Frontend
import Api.Auxiliary exposing (RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
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
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Page as Page exposing (RecipeMap)
import Pages.MealEntries.Pagination as Pagination
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput
import Pages.Meals.View
import Pages.Util.DictListUtil as DictUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate
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
        , currentPage = Nothing
        , showNavigation = True
        }
        main
    <|
        let
            viewMealEntryState =
                Editing.unpack
                    { onView = viewMealEntryLine configuration main.recipes
                    , onUpdate = updateEntryLine main.recipes
                    , onDelete = deleteMealEntryLine main.recipes
                    }

            viewMealEntries =
                main.mealEntries
                    |> DictList.values
                    |> List.filter (\v -> SearchUtil.search main.entriesSearchString (DictUtil.nameOrEmpty main.recipes v.original.recipeId))
                    |> List.sortBy (.original >> .recipeId >> DictUtil.nameOrEmpty main.recipes >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.mealEntries
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
                main.mealEntriesToAdd
                    |> DictList.isEmpty
                    |> not

            numberOfServings =
                if anySelection then
                    "Servings"

                else
                    ""

            viewMeal =
                Editing.unpack
                    { onView =
                        Pages.Meals.View.mealLineWith
                            { controls =
                                [ td [ Style.classes.controls ]
                                    [ button [ Style.classes.button.edit, Page.EnterEditMeal |> onClick ] [ text "Edit" ] ]
                                , td [ Style.classes.controls ]
                                    [ button
                                        [ Style.classes.button.delete, Page.RequestDeleteMeal |> onClick ]
                                        [ text "Delete" ]
                                    ]
                                , td [ Style.classes.controls ]
                                    [ Links.linkButton
                                        { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsMealSelect.address <| main.meal.original.id
                                        , attributes = [ Style.classes.button.nutrients ]
                                        , children = [ text "Nutrients" ]
                                        }
                                    ]
                                ]
                            , onClick = [ Page.EnterEditMeal |> onClick ]
                            , styles = []
                            }
                    , onUpdate =
                        Pages.Meals.View.editMealLineWith
                            { saveMsg = Page.SaveMealEdit
                            , dateLens = MealUpdateClientInput.lenses.date
                            , setDate = True
                            , nameLens = MealUpdateClientInput.lenses.name
                            , updateMsg = Page.UpdateMeal
                            , confirmName = "Save"
                            , cancelMsg = Page.ExitEditMeal
                            , cancelName = "Cancel"
                            , rowStyles = []
                            }
                            |> always
                    , onDelete =
                        Pages.Meals.View.mealLineWith
                            { controls =
                                [ td [ Style.classes.controls ]
                                    [ button [ Style.classes.button.delete, onClick <| Page.ConfirmDeleteMeal ] [ text "Delete?" ] ]
                                , td [ Style.classes.controls ]
                                    [ button
                                        [ Style.classes.button.confirm, onClick <| Page.CancelDeleteMeal ]
                                        [ text "Cancel" ]
                                    ]
                                ]
                            , onClick = []
                            , styles = []
                            }
                    }
                    main.meal
        in
        div [ Style.ids.mealEntryEditor ]
            [ div []
                [ table [ Style.classes.elementsWithControlsTable ]
                    (Pages.Meals.View.tableHeader { controlButtons = 3 }
                        ++ [ tbody [] [ viewMeal ]
                           ]
                    )
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Dishes" ] ]
            , div [ Style.classes.choices ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetEntriesSearchString
                    , searchString = main.entriesSearchString
                    }
                , table [ Style.classes.elementsWithControlsTable, Style.classes.recipeEditTable ]
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "3" ] []
                        ]
                    , thead []
                        [ tr []
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col" ] [ label [] [ text "Description" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
                            , th [ colspan 3, scope "colgroup", Style.classes.controlsGroup ] []
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
                                { pagination = Page.lenses.main.pagination
                                , items = Pagination.lenses.mealEntries
                                }
                                main
                                >> Page.SetPagination
                        , elements = viewMealEntries
                        }
                    ]
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetRecipesSearchString
                        , searchString = main.recipesSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable, Style.classes.recipeEditTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col" ] [ label [] [ text "Description" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text numberOfServings ] ]
                                , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeLine configuration main.mealEntriesToAdd main.mealEntries)
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


viewMealEntryLine : Configuration -> Page.RecipeMap -> MealEntry -> Html Page.LogicMsg
viewMealEntryLine configuration recipeMap mealEntry =
    let
        editMsg =
            Page.EnterEditMealEntry mealEntry.id |> onClick
    in
    mealEntryLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteMealEntry mealEntry.id) ] [ text "Delete" ] ]
            , td [ Style.classes.controls ] [ recipeLinkButton configuration mealEntry.recipeId ]
            ]
        , onClick = [ editMsg ]
        , recipeMap = recipeMap
        }
        mealEntry


deleteMealEntryLine : Page.RecipeMap -> MealEntry -> Html Page.LogicMsg
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
    { controls : List (Html Page.LogicMsg)
    , onClick : List (Attribute Page.LogicMsg)
    , recipeMap : Page.RecipeMap
    }
    -> MealEntry
    -> Html Page.LogicMsg
mealEntryLineWith ps mealEntry =
    let
        withOnClick =
            (++) ps.onClick
    in
    tr [ Style.classes.editing ]
        (recipeInfo ps.recipeMap mealEntry.recipeId ([ Style.classes.editable ] |> withOnClick)
            ++ [ td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| String.fromFloat <| mealEntry.numberOfServings ] ]
               ]
            ++ ps.controls
        )


updateEntryLine : Page.RecipeMap -> MealEntry -> MealEntryUpdateClientInput -> Html Page.LogicMsg
updateEntryLine recipeMap mealEntry mealEntryUpdateClientInput =
    let
        saveMsg =
            Page.SaveMealEntryEdit mealEntryUpdateClientInput

        cancelMsg =
            Page.ExitEditMealEntryAt mealEntry.id
    in
    tr [ Style.classes.editLine ]
        (recipeInfo recipeMap mealEntry.recipeId []
            ++ [ td [ Style.classes.numberCell ]
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
        )


recipeInfo : Page.RecipeMap -> RecipeId -> List (Attribute Page.LogicMsg) -> List (Html Page.LogicMsg)
recipeInfo recipeMap recipeId attributes =
    let
        recipe =
            DictList.get recipeId recipeMap
    in
    [ td attributes [ label [] [ text <| Maybe.Extra.unwrap "" .name <| recipe ] ]
    , td attributes [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .description <| recipe ] ]
    , td (Style.classes.numberCell :: attributes) [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .servingSize <| recipe ] ]
    ]


viewRecipeLine : Configuration -> Page.AddMealEntriesMap -> Page.MealEntryStateMap -> Recipe -> Html Page.LogicMsg
viewRecipeLine configuration mealEntriesToAdd mealEntries recipe =
    let
        addMsg =
            Page.AddRecipe recipe.id

        selectMsg =
            Page.SelectRecipe recipe.id

        maybeRecipeToAdd =
            DictList.get recipe.id mealEntriesToAdd

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
                    , td [ Style.classes.controls ] [ recipeLinkButton configuration recipe.id ]
                    ]

                Just mealEntryToAdd ->
                    let
                        validInput =
                            mealEntryToAdd.numberOfServings |> ValidatedInput.isValid

                        ( confirmName, confirmStyle ) =
                            if DictUtil.existsValue (\mealEntry -> mealEntry.original.recipeId == mealEntryToAdd.recipeId) mealEntries then
                                ( "Add again", Style.classes.button.edit )

                            else
                                ( "Add", Style.classes.button.confirm )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            ([ MaybeUtil.defined <| value mealEntryToAdd.numberOfServings.text
                             , MaybeUtil.defined <|
                                onInput <|
                                    flip
                                        (ValidatedInput.lift
                                            MealEntryCreationClientInput.lenses.numberOfServings
                                        ).set
                                        mealEntryToAdd
                                        >> Page.UpdateAddRecipe
                             , MaybeUtil.defined <| Style.classes.numberLabel
                             , MaybeUtil.optional validInput <| onEnter addMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            []
                        ]
                    , td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| confirmStyle
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick addMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text confirmName ]
                        ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.cancel, onClick (Page.DeselectRecipe recipe.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr ([ Style.classes.editing ] ++ rowClickAction)
        (td [] [ label [] [ text recipe.name ] ]
            :: td [] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
            :: td [ Style.classes.numberCell ] [ label [] [ text <| Maybe.withDefault "" <| recipe.servingSize ] ]
            :: process
        )


recipeLinkButton : Configuration -> RecipeId -> Html msg
recipeLinkButton configuration recipeId =
    Links.linkButton
        { url =
            recipeId
                |> Addresses.Frontend.ingredientEditor.address
                |> Links.frontendPage configuration
        , attributes = [ Style.classes.button.editor ]
        , children = [ text "Recipe" ]
        }
