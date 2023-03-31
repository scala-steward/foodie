module Pages.Meals.View exposing (editMealLineWith, mealLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.Meal exposing (Meal)
import Api.Types.SimpleDate exposing (SimpleDate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Html exposing (Attribute, Html, button, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, type_, value)
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
                createMeal main.mealToAdd
                    |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
                    |> Tuple.mapBoth List.concat List.concat
        in
        div [ Style.ids.addMealView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (tableHeader
                            ++ [ tbody []
                                    (creationLine
                                        ++ (viewMeals
                                                |> Paginate.page
                                                |> List.concatMap viewMealState
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


tableHeader : List (Html msg)
tableHeader =
    [ thead []
        [ tr [ Style.classes.tableHeader, Style.classes.mealEditTable ]
            [ th [] [ label [] [ text "Date" ] ]
            , th [] [ label [] [ text "Time" ] ]
            , th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.toggle ] []
            ]
        ]
    ]


createMeal : Maybe MealCreationClientInput -> Either (List (Html Page.LogicMsg)) (List (Html Page.LogicMsg))
createMeal maybeCreation =
    case maybeCreation of
        Nothing ->
            [ div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick (MealCreationClientInput.default |> Just |> Page.UpdateMealCreation)
                    ]
                    [ text "New meal" ]
                ]
            ]
                |> Left

        Just creation ->
            createMealLine creation |> Right


viewMealLine : Configuration -> Meal -> Bool -> List (Html Page.LogicMsg)
viewMealLine configuration meal showControls =
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, Page.EnterEditMeal meal.id |> onClick ] [ text "Edit" ] ]
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
        , toggleCommand = Page.ToggleControls meal.id
        , showControls = showControls
        }
        meal


deleteMealLine : Meal -> List (Html Page.LogicMsg)
deleteMealLine meal =
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteMeal meal.id) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ]
                [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteMeal meal.id) ] [ text "Cancel" ] ]
            ]
        , toggleCommand = Page.ToggleControls meal.id
        , showControls = True
        }
        meal



-- todo: Check back for duplication (cf. recipeLineWith).


mealLineWith :
    { controls : List (Html msg)
    , toggleCommand : msg
    , showControls : Bool
    }
    -> Meal
    -> List (Html msg)
mealLineWith ps meal =
    let
        withOnClick =
            (::) (ps.toggleCommand |> onClick)

        infoRow =
            tr [ Style.classes.editing ]
                [ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
                , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
                , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
                , HtmlUtil.toggleControlsCell ps.toggleCommand
                ]

        controlsRow =
            tr []
                [ td [ colspan 3 ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] ps.controls ] ]
                ]
    in
    infoRow
        :: (if ps.showControls then
                [ controlsRow ]

            else
                []
           )


updateMealLine : MealUpdateClientInput -> List (Html Page.LogicMsg)
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
        , toggleCommand = Page.ToggleControls mealUpdateClientInput.id |> Just
        }
        mealUpdateClientInput


createMealLine : MealCreationClientInput -> List (Html Page.LogicMsg)
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
        , toggleCommand = Nothing
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
    , toggleCommand : Maybe msg
    }
    -> editedValue
    -> List (Html msg)
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

        -- todo: Check back, whether it is sensible to extract this block (cf. same block for recipes).
        controlsRow =
            tr []
                [ td [ colspan 3 ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr []
                            [ td [ Style.classes.controls ]
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
                        ]
                    ]
                ]

        commandToggle =
            handling.toggleCommand
                |> Maybe.Extra.unwrap []
                    (HtmlUtil.toggleControlsCell >> List.singleton)
    in
    [ tr handling.rowStyles
        ([ td [ Style.classes.editable, Style.classes.date ]
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
         ]
            ++ commandToggle
        )
    , controlsRow
    ]
