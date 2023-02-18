module Pages.Meals.View exposing (editMealLineWith, mealLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.Meal exposing (Meal)
import Api.Types.SimpleDate exposing (SimpleDate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
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
import Pages.Util.DateUtil as DateUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.SimpleDateInput as SimpleDateInput exposing (SimpleDateInput)
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate
import Parser
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
        , currentPage = Just ViewUtil.Meals
        , showNavigation = True
        }
        main
    <|
        let
            viewMealState =
                Editing.unpack
                    { onView = viewMealLine configuration
                    , onUpdate = updateMealLine |> always
                    , onDelete = deleteMealLine
                    }

            filterOn =
                SearchUtil.search main.searchString

            viewMeals =
                main.meals
                    |> DictList.filter
                        (\_ v ->
                            filterOn (v.original.name |> Maybe.withDefault "")
                                || filterOn (v.original.date |> DateUtil.toString)
                        )
                    |> DictList.values
                    |> List.sortBy (.original >> .date >> DateUtil.toString)
                    |> List.reverse
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.meals }
                        main

            ( button, creationLine ) =
                createMeal main.mealToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ Style.ids.addMealView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (tableHeader { controlButtons = 4 }
                            ++ [ tbody []
                                    (creationLine
                                        ++ (viewMeals
                                                |> Paginate.page
                                                |> List.map viewMealState
                                           )
                                    )
                               ]
                        )
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.meals
                                    }
                                    main
                                    >> Page.SetPagination
                            , elements = viewMeals
                            }
                        ]
                   ]
            )


tableHeader : { controlButtons : Int } -> List (Html msg)
tableHeader ps =
    [ colgroup []
        [ col [] []
        , col [] []
        , col [] []
        , col [ stringProperty "span" <| String.fromInt <| ps.controlButtons ] []
        ]
    , thead []
        [ tr [ Style.classes.tableHeader ]
            [ th [ scope "col" ] [ label [] [ text "Date" ] ]
            , th [ scope "col" ] [ label [] [ text "Time" ] ]
            , th [ scope "col" ] [ label [] [ text "Name" ] ]
            , th [ colspan ps.controlButtons, scope "colgroup", Style.classes.controlsGroup ] []
            ]
        ]
    ]


createMeal : Maybe MealCreationClientInput -> Either (Html Page.LogicMsg) (Html Page.LogicMsg)
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


viewMealLine : Configuration -> Meal -> Html Page.LogicMsg
viewMealLine configuration meal =
    let
        editMsg =
            Page.EnterEditMeal meal.id |> onClick
    in
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.mealEntryEditor.address <| meal.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Entries" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteMeal meal.id) ] [ text "Delete" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsMealSelect.address <| meal.id
                    , attributes = [ Style.classes.button.nutrients ]
                    , children = [ text "Nutrients" ]
                    }
                ]
            ]
        , onClick = [ editMsg ]
        , styles = [ Style.classes.editing ]
        }
        meal


deleteMealLine : Meal -> Html Page.LogicMsg
deleteMealLine meal =
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteMeal meal.id) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteMeal meal.id) ] [ text "Cancel" ] ]
            ]
        , onClick = []
        , styles = [ Style.classes.editing ]
        }
        meal


mealLineWith :
    { controls : List (Html msg)
    , onClick : List (Attribute msg)
    , styles : List (Attribute msg)
    }
    -> Meal
    -> Html msg
mealLineWith ps meal =
    let
        withOnClick =
            (++) ps.onClick
    in
    tr ps.styles
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
         , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
         , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
         ]
            ++ ps.controls
        )


updateMealLine : MealUpdateClientInput -> Html Page.LogicMsg
updateMealLine mealUpdateClientInput =
    editMealLineWith
        { saveMsg = Page.SaveMealEdit mealUpdateClientInput.id
        , dateLens = MealUpdateClientInput.lenses.date
        , setDate = True
        , nameLens = MealUpdateClientInput.lenses.name
        , updateMsg = Page.UpdateMeal
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditMealAt mealUpdateClientInput.id
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        }
        mealUpdateClientInput


createMealLine : MealCreationClientInput -> Html Page.LogicMsg
createMealLine mealCreation =
    editMealLineWith
        { saveMsg = Page.CreateMeal
        , dateLens = MealCreationClientInput.lenses.date
        , setDate = False
        , nameLens = MealCreationClientInput.lenses.name
        , updateMsg = Just >> Page.UpdateMealCreation
        , confirmName = "Add"
        , cancelMsg = Page.UpdateMealCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        }
        mealCreation


editMealLineWith :
    { saveMsg : msg
    , dateLens : Lens editedValue SimpleDateInput
    , setDate : Bool
    , nameLens : Optional editedValue String
    , updateMsg : editedValue -> msg
    , confirmName : String
    , cancelMsg : msg
    , cancelName : String
    , rowStyles : List (Attribute msg)
    }
    -> editedValue
    -> Html msg
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
            MaybeUtil.optional (deepDateLens.get editedValue |> Maybe.Extra.isJust) <| onEnter handling.saveMsg

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
    tr handling.rowStyles
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
                ([ MaybeUtil.defined <| value <| name
                 , MaybeUtil.defined <|
                    onInput <|
                        flip handling.nameLens.set editedValue
                            >> handling.updateMsg
                 , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                 , validatedSaveAction
                 ]
                    |> Maybe.Extra.values
                )
                []
            ]
        , td [ Style.classes.controls ]
            [ button
                ([ MaybeUtil.defined <| Style.classes.button.confirm
                 , MaybeUtil.defined <| disabled <| not <| validInput
                 , MaybeUtil.optional validInput <| onClick handling.saveMsg
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
