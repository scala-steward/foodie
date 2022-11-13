module Pages.Statistics.Time.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
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
import Paginate
import Parser


view : Page.Model -> Html Page.Msg
view model =
    let
        viewMeals =
            model.stats.meals
                |> List.sortBy (.date >> DateUtil.toString)
                |> List.reverse
                |> ViewUtil.paginate
                    { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.meals
                    }
                    model
    in
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just ViewUtil.Statistics
        , showNavigation = True
        }
        model
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = model.authorizedAccess.configuration.mainPageURL
            , currentPage = Just StatisticsVariant.Time
            }
        <|
            div [ Style.ids.statistics ]
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
                                [ td [ Style.classes.editable, Style.classes.date ] [ dateInput model Page.SetFromDate Page.lenses.from ]
                                , td [ Style.classes.editable, Style.classes.date ] [ dateInput model Page.SetToDate Page.lenses.to ]
                                , td [ Style.classes.controls ]
                                    [ button
                                        [ Style.classes.button.select, onClick Page.FetchStats ]
                                        [ text "Compute" ]
                                    ]
                                , td [ Style.classes.controls ]
                                    ([ Links.loadingSymbol ] |> List.filter (always model.fetching))
                                ]
                            ]
                        ]
                    ]
                    :: StatisticsView.statisticsTable
                        { onReferenceMapSelection = Page.SelectReferenceMap
                        , onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .stats >> .nutrients
                        , amountOf = .amounts >> .values >> Maybe.map .total
                        , dailyAmountOf = Just (.amounts >> .values >> Maybe.map .dailyAverage)
                        , completenessFraction =
                            Just
                                { definedValues = .amounts >> .numberOfDefinedValues
                                , totalValues = .amounts >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients in the meal"
                        }
                        model
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
                                            { pagination = Page.lenses.pagination
                                            , items = Pagination.lenses.meals
                                            }
                                            model
                                            >> Page.SetPagination
                                    , elements = viewMeals
                                    }
                                ]
                            ]
                       ]
                )


mealLine : Meal -> Html Page.Msg
mealLine meal =
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable, Style.classes.date ] [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ Style.classes.editable, Style.classes.time ] [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ Style.classes.editable ] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        ]


dateInput : Page.Model -> (Maybe Date -> c) -> Lens Page.Model (Maybe Date) -> Html c
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
