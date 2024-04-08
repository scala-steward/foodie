module Pages.Statistics.Recipe.Search.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Recipe exposing (Recipe)
import Configuration exposing (Configuration)
import Html exposing (Html, div, label, table, tbody, td, text, th, thead, tr)
import Monocle.Compose as Compose
import Pages.Statistics.Recipe.Search.Page as Page
import Pages.Statistics.Recipe.Search.Pagination as Pagination
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
        , currentPage = Just Statistics
        , showNavigation = True
        }
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = configuration.mainPageURL
            , currentPage = Just StatisticsVariant.Recipe
            }
        <|
            let
                filterOn =
                    SearchUtil.search main.recipesSearchString

                viewRecipes =
                    main.recipes
                        |> List.filter
                            (\v ->
                                filterOn v.name
                                    || filterOn (v.description |> Maybe.withDefault "")
                            )
                        |> List.sortBy .name
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.main.pagination
                                    |> Compose.lensWithLens Pagination.lenses.recipes
                            }
                            main
            in
            div [ Style.ids.statistics.recipe ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.recipesSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Name" ] ]
                                , th [] [ label [] [ text "Description" ] ]
                                , th [] []
                                , th [] []
                                ]
                            ]
                        , tbody []
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeLine configuration)
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
                                    >> Page.SetRecipesPagination
                            , elements = viewRecipes
                            }
                        ]
                    ]
                ]


viewRecipeLine : Configuration -> Recipe -> Html Page.LogicMsg
viewRecipeLine configuration recipe =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text recipe.name ] ]
        , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.recipeNutrientsLinkButton configuration recipe.id ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.recipeEditorLinkButton configuration recipe.id ]
        ]
