module Pages.Meals.View exposing (view)

import Addresses.Frontend
import Api.Types.Meal exposing (Meal)
import Api.Types.SimpleDate exposing (SimpleDate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, type_, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Pagination as Pagination
import Pages.Meals.Status as Status
import Pages.Util.DateUtil as DateUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.SimpleDateInput as SimpleDateInput exposing (SimpleDateInput)
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Parser
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just ViewUtil.Meals
        , showNavigation = True
        }
        model
    <|
        let
            viewMealState =
                Editing.unpack
                    { onView = viewMealLine model.authorizedAccess.configuration
                    , onUpdate = updateMealLine |> always
                    , onDelete = deleteMealLine model.authorizedAccess.configuration
                    }

            filterOn =
                SearchUtil.search model.searchString

            viewMeals =
                model.meals
                    |> Dict.filter
                        (\_ v ->
                            filterOn (v.original.name |> Maybe.withDefault "")
                                || filterOn (v.original.date |> DateUtil.toString)
                        )
                    |> Dict.values
                    |> List.sortBy (.original >> .date >> DateUtil.toString)
                    |> List.reverse
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.meals }
                        model

            ( button, creationLine ) =
                createMeal model.mealToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ Style.ids.addMealView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = model.searchString
                        }
                   , table []
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "3" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Date" ] ]
                                , th [ scope "col" ] [ label [] [ text "Time" ] ]
                                , th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ colspan 3, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (creationLine
                                ++ (viewMeals
                                        |> Paginate.page
                                        |> List.map viewMealState
                                   )
                            )
                        ]
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.meals
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewMeals
                            }
                        ]
                   ]
            )


createMeal : Maybe MealCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createMeal maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick (MealCreationClientInput.default |> Just |> Page.UpdateMealCreation)
                    ]
                    [ text "New meal" ]
                ]
                |> Left

        Just creation ->
            createMealLine creation |> Right


viewMealLine : Configuration -> Meal -> Html Page.Msg
viewMealLine configuration meal =
    let
        editMsg =
            Page.EnterEditMeal meal.id |> onClick
    in
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteMeal meal.id) ] [ text "Delete" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.mealEntryEditor.address <| meal.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Entries" ]
                    }
                ]
            ]
        , onClick = [ editMsg ]
        , configuration = configuration
        }
        meal


deleteMealLine : Configuration -> Meal -> Html Page.Msg
deleteMealLine configuration meal =
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteMeal meal.id) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteMeal meal.id) ] [ text "Cancel" ] ]
            ]
        , onClick = []
        , configuration = configuration
        }
        meal


mealLineWith :
    { controls : List (Html Page.Msg)
    , onClick : List (Attribute Page.Msg)
    , configuration : Configuration
    }
    -> Meal
    -> Html Page.Msg
mealLineWith ps meal =
    let
        withOnClick =
            (++) ps.onClick
    in
    tr [ Style.classes.editing ]
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
         , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
         , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
         ]
            ++ ps.controls
        )


updateMealLine : MealUpdateClientInput -> Html Page.Msg
updateMealLine mealUpdateClientInput =
    editMealLineWith
        { saveMsg = Page.SaveMealEdit mealUpdateClientInput.id
        , dateLens = MealUpdateClientInput.lenses.date
        , setDate = True
        , nameLens = MealUpdateClientInput.lenses.name
        , updateMsg = Page.UpdateMeal
        , confirmOnClick = Page.SaveMealEdit mealUpdateClientInput.id
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditMealAt mealUpdateClientInput.id
        , cancelName = "Cancel"
        }
        mealUpdateClientInput


createMealLine : MealCreationClientInput -> Html Page.Msg
createMealLine mealCreation =
    editMealLineWith
        { saveMsg = Page.CreateMeal
        , dateLens = MealCreationClientInput.lenses.date
        , setDate = False
        , nameLens = MealCreationClientInput.lenses.name
        , updateMsg = Just >> Page.UpdateMealCreation
        , confirmOnClick = Page.CreateMeal
        , confirmName = "Add"
        , cancelMsg = Page.UpdateMealCreation Nothing
        , cancelName = "Cancel"
        }
        mealCreation


editMealLineWith :
    { saveMsg : Page.Msg
    , dateLens : Lens editedValue SimpleDateInput
    , setDate : Bool
    , nameLens : Optional editedValue String
    , updateMsg : editedValue -> Page.Msg
    , confirmOnClick : Page.Msg
    , confirmName : String
    , cancelMsg : Page.Msg
    , cancelName : String
    }
    -> editedValue
    -> Html Page.Msg
editMealLineWith handling editedValue =
    let
        date =
            handling.dateLens.get <| editedValue

        deepDateLens =
            handling.dateLens
                |> Compose.lensWithLens SimpleDateInput.lenses.date

        deepTimeLens =
            handling.dateLens
                |> Compose.lensWithLens SimpleDateInput.lenses.time

        dateValue =
            date
                |> .date
                |> Maybe.Extra.filter (\_ -> handling.setDate)
                |> Maybe.map (DateUtil.dateToString >> value)
                |> Maybe.Extra.toList

        dateParsedInteraction =
            Parser.run DateUtil.dateParser
                >> Result.toMaybe
                >> flip
                    deepDateLens.set
                    editedValue
                >> handling.updateMsg

        validatedSaveAction =
            HtmlUtil.optional (deepDateLens.get editedValue |> Maybe.Extra.isJust) <| onEnter handling.saveMsg

        timeValue =
            date
                |> .time
                |> Maybe.Extra.filter (\_ -> handling.setDate)
                |> Maybe.map (DateUtil.timeToString >> value)
                |> Maybe.Extra.toList

        timeInteraction =
            Parser.run DateUtil.timeParser
                >> Result.toMaybe
                >> flip
                    deepTimeLens.set
                    editedValue
                >> handling.updateMsg

        name =
            Maybe.withDefault "" <| handling.nameLens.getOption <| editedValue

        validInput =
            Maybe.Extra.isJust <| date.date
    in
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable, Style.classes.date ]
            [ input
                ([ type_ "date"
                 , Style.classes.date
                 , onInput dateParsedInteraction
                 , HtmlUtil.onEscape handling.cancelMsg
                 ]
                    ++ dateValue
                )
                []
            ]
        , td [ Style.classes.editable, Style.classes.time ]
            [ input
                ([ type_ "time"
                 , Style.classes.time
                 , onInput timeInteraction
                 , HtmlUtil.onEscape handling.cancelMsg
                 ]
                    ++ timeValue
                )
                []
            ]
        , td [ Style.classes.editable ]
            [ input
                ([ HtmlUtil.defined <| value <| name
                 , HtmlUtil.defined <|
                    onInput <|
                        flip handling.nameLens.set editedValue
                            >> handling.updateMsg
                 , HtmlUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                 , validatedSaveAction
                 ]
                    |> Maybe.Extra.values
                )
                []
            ]
        , td [ Style.classes.controls ]
            [ button
                ([ HtmlUtil.defined <| Style.classes.button.confirm
                 , HtmlUtil.defined <| disabled <| not <| validInput
                 , HtmlUtil.optional validInput <| onClick handling.confirmOnClick
                 ]
                    |> Maybe.Extra.values
                )
                [ text handling.confirmName ]
            ]
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.cancel, onClick handling.cancelMsg ]
                [ text handling.cancelName ]
            ]
        ]
