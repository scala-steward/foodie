module Pages.Statistics.Recipe.Search.View exposing (view)

import Addresses.Frontend
import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Recipe exposing (Recipe)
import Configuration exposing (Configuration)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Monocle.Compose as Compose
import Pages.Statistics.Recipe.Search.Page as Page
import Pages.Statistics.Recipe.Search.Pagination as Pagination
import Pages.Statistics.Recipe.Search.Status as Status
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
            , currentPage = Just <| StatisticsVariant.Recipe StatisticsVariant.None
            }
        <|
            let
                viewRecipes =
                    model.recipes
                        |> List.filter (\v -> SearchUtil.search model.recipesSearchString v.name)
                        |> List.sortBy .name
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.pagination
                                    |> Compose.lensWithLens Pagination.lenses.recipes
                            }
                            model
            in
            div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = model.recipesSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Name" ] ]
                                , th [] [ label [] [ text "Description" ] ]
                                , th [ Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeLine model.authorizedAccess.configuration)
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
                                    >> Page.SetRecipesPagination
                            , elements = viewRecipes
                            }
                        ]
                    ]
                ]


viewRecipeLine : Configuration -> Recipe -> Html Page.Msg
viewRecipeLine configuration recipe =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text recipe.name ] ]
        , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsRecipeSelect.address <| recipe.id
                , attributes = [ Style.classes.button.editor ]
                , children = [ text "Nutrients" ]
                }
            ]
        ]
