module Pages.Statistics.Time.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, scope, type_, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Statistics.Time.Page as Page
import Pages.Statistics.Time.Pagination as Pagination
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate
import Parser
import Uuid


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    let
        viewMeals =
            main.stats.meals
                |> List.sortBy (.date >> DateUtil.toString)
                |> List.reverse
                |> ViewUtil.paginate
                    { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.meals
                    }
                    main

        weightRow =
            case main.status of
                Page.Display ->
                    [ div [ Style.classes.elements ]
                        [ label
                            []
                            [ text <| (++) "Weight of ingredients: " <| flip (++) "g" <| StatisticsView.displayFloat <| .weightInGrams <| main.stats ]
                        ]
                    ]

                _ ->
                    []

        stats =
            case main.status of
                Page.Display ->
                    StatisticsView.statisticsTable
                        { onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .stats >> .nutrients
                        , amountOf = .amounts >> .values >> Maybe.map .total
                        , dailyAmountOf = .amounts >> .values >> Maybe.map .dailyAverage
                        , showDailyAmount = True
                        , completenessFraction =
                            Just
                                { definedValues = .amounts >> .numberOfDefinedValues
                                , totalValues = .amounts >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients in all meals in the interval"
                        }
                        main
                        ++ [ div [ Style.classes.elements ] [ text "Meals" ]
                           , div [ Style.classes.info, Style.classes.meals ]
                                [ table [ Style.classes.elementsWithControlsTable ]
                                    [ thead []
                                        [ tr []
                                            [ th [] [ label [] [ text "Date" ] ]
                                            , th [] [ label [] [ text "Time" ] ]
                                            , th [] [ label [] [ text "Name" ] ]
                                            , th [] [ label [] [ text "Description" ] ]
                                            ]
                                        ]
                                    , tbody []
                                        (viewMeals
                                            |> Paginate.page
                                            |> List.map mealLine
                                        )
                                    ]
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
                           ]

                _ ->
                    []
    in
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Just ViewUtil.Statistics
        , showNavigation = True
        }
        main
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = configuration.mainPageURL
            , currentPage = Just StatisticsVariant.Time
            }
        <|
            div [ Style.ids.statistics.time ]
                (div []
                    [ table [ Style.classes.intervalSelection, Style.classes.elementsWithControlsTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "From" ] ]
                                , th [ scope "col" ] [ label [] [ text "To" ] ]
                                , th [ colspan 2, scope "col", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            [ tr []
                                [ td [ Style.classes.editable, Style.classes.date ] [ dateInput main Page.SetFromDate Page.lenses.main.from ]
                                , td [ Style.classes.editable, Style.classes.date ] [ dateInput main Page.SetToDate Page.lenses.main.to ]
                                , td [ Style.classes.controls ]
                                    [ button
                                        [ Style.classes.button.select, onClick Page.FetchStats ]
                                        [ text "Compute" ]
                                    ]
                                , td [ Style.classes.controls ]
                                    ([ Links.loadingSymbol ] |> List.filter (always (main.status == Page.Fetch)))
                                ]
                            ]
                        ]
                    ]
                    :: StatisticsView.referenceMapSelection
                        { onReferenceMapSelection = Maybe.andThen Uuid.fromString >> Page.SelectReferenceMap
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        }
                        main
                    ++ weightRow
                    ++ stats
                )


mealLine : Meal -> Html Page.LogicMsg
mealLine meal =
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable, Style.classes.date ] [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ Style.classes.editable, Style.classes.time ] [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ Style.classes.editable ] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        ]


dateInput : Page.Main -> (Maybe Date -> c) -> Lens Page.Main (Maybe Date) -> Html c
dateInput model mkCmd lens =
    input
        [ type_ "date"
        , value <| Maybe.Extra.unwrap "" DateUtil.dateToString <| lens.get <| model
        , onInput
            (Parser.run DateUtil.dateParser
                >> Result.toMaybe
                >> mkCmd
            )
        , Style.classes.date
        ]
        []
