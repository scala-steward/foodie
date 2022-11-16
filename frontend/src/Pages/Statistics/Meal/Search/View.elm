module Pages.Statistics.Meal.Search.View exposing (view)

import Addresses.Frontend
import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Meal exposing (Meal)
import Configuration exposing (Configuration)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Statistics.Meal.Search.Page as Page
import Pages.Statistics.Meal.Search.Pagination as Pagination
import Pages.Statistics.Meal.Search.Status as Status
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.DateUtil as DateUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
import Paginate
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just Statistics
        , showNavigation = True
        }
        model
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = model.authorizedAccess.configuration.mainPageURL
            , currentPage = Just StatisticsVariant.Meal
            }
        <|
            let
                filterOn =
                    SearchUtil.search model.mealsSearchString

                viewMeals =
                    model.meals
                        |> List.filter
                            (\v ->
                                filterOn (v.name |> Maybe.withDefault "")
                                    || filterOn (v.date |> DateUtil.toString)
                            )
                        |> List.sortBy (.date >> DateUtil.toString)
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.pagination
                                    |> Compose.lensWithLens Pagination.lenses.meals
                            }
                            model
            in
            div [ Style.ids.statistics.meal ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = model.mealsSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Date" ] ]
                                , th [] [ label [] [ text "Time" ] ]
                                , th [] [ label [] [ text "Name" ] ]
                                , th [ Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewMeals
                                |> Paginate.page
                                |> List.map (viewMealLine model.authorizedAccess.configuration)
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
                                    >> Page.SetMealsPagination
                            , elements = viewMeals
                            }
                        ]
                    ]
                ]


viewMealLine : Configuration -> Meal -> Html Page.Msg
viewMealLine configuration meal =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsMealSelect.address <| meal.id
                , attributes = [ Style.classes.button.nutrients ]
                , children = [ text "Nutrients" ]
                }
            ]
        ]
