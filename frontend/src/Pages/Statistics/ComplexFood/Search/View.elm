module Pages.Statistics.ComplexFood.Search.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.ComplexFood exposing (ComplexFood)
import Configuration exposing (Configuration)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Monocle.Compose as Compose
import Pages.Statistics.ComplexFood.Search.Page as Page
import Pages.Statistics.ComplexFood.Search.Pagination as Pagination
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
import Pages.View.Tristate as Tristate
import Paginate
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
        , currentPage = Just Statistics
        , showNavigation = True
        }
        main
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = configuration.mainPageURL
            , currentPage = Just StatisticsVariant.ComplexFood
            }
        <|
            let
                filterOn =
                    SearchUtil.search main.complexFoodsSearchString

                viewComplexFoods =
                    main.complexFoods
                        |> List.filter
                            (\v ->
                                filterOn v.name
                                    || filterOn (v.description |> Maybe.withDefault "")
                            )
                        |> List.sortBy .name
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.main.pagination
                                    |> Compose.lensWithLens Pagination.lenses.complexFoods
                            }
                            main
            in
            div [ Style.ids.statistics.complexFood ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.complexFoodsSearchString
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
                                |> List.map (viewComplexFoodLine configuration)
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
                                    >> Page.SetComplexFoodsPagination
                            , elements = viewComplexFoods
                            }
                        ]
                    ]
                ]


viewComplexFoodLine : Configuration -> ComplexFood -> Html Page.LogicMsg
viewComplexFoodLine configuration complexFood =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text complexFood.name ] ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.complexFoodNutrientLinkButton configuration complexFood.recipeId ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.recipeEditorLinkButton configuration complexFood.recipeId ]
        ]
