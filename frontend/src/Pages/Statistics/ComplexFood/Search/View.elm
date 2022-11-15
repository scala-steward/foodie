module Pages.Statistics.ComplexFood.Search.View exposing (view)

import Addresses.Frontend
import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.ComplexFood exposing (ComplexFood)
import Configuration exposing (Configuration)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Monocle.Compose as Compose
import Pages.Statistics.ComplexFood.Search.Page as Page
import Pages.Statistics.ComplexFood.Search.Pagination as Pagination
import Pages.Statistics.ComplexFood.Search.Status as Status
import Pages.Statistics.StatisticsView as StatisticsView
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
            , currentPage = Just StatisticsVariant.ComplexFood
            }
        <|
            let
                filterOn =
                    SearchUtil.search model.complexFoodsSearchString

                viewComplexFoods =
                    model.complexFoods
                        |> List.filter
                            (\v ->
                                filterOn v.name
                                    || filterOn (v.description |> Maybe.withDefault "")
                            )
                        |> List.sortBy .name
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.pagination
                                    |> Compose.lensWithLens Pagination.lenses.complexFoods
                            }
                            model
            in
            div [ Style.ids.statistics.complexFood ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = model.complexFoodsSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Name" ] ]
                                , th [ Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewComplexFoods
                                |> Paginate.page
                                |> List.map (viewComplexFoodLine model.authorizedAccess.configuration)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.complexFoods
                                    }
                                    model
                                    >> Page.SetComplexFoodsPagination
                            , elements = viewComplexFoods
                            }
                        ]
                    ]
                ]


viewComplexFoodLine : Configuration -> ComplexFood -> Html Page.Msg
viewComplexFoodLine configuration complexFood =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text complexFood.name ] ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsComplexFoodSelect.address <| complexFood.recipeId
                , attributes = [ Style.classes.button.nutrients ]
                , children = [ text "Nutrients" ]
                }
            ]
        ]
