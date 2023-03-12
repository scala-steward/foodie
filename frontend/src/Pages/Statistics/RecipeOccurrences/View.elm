module Pages.Statistics.RecipeOccurrences.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.RecipeOccurrence exposing (RecipeOccurrence)
import Configuration exposing (Configuration)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Statistics.RecipeOccurrences.Page as Page
import Pages.Statistics.RecipeOccurrences.Pagination as Pagination
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.DateUtil as DateUtil
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
            , currentPage = Just StatisticsVariant.Recipe
            }
        <|
            let
                filterOn =
                    SearchUtil.search main.recipesSearchString

                viewRecipes =
                    main.recipeOccurrences
                        |> List.filter
                            (\v ->
                                filterOn v.recipe.name
                                    || filterOn (v.recipe.description |> Maybe.withDefault "")
                                    || filterOn (v.lastUsedInMeal |> Maybe.Extra.unwrap "" (.date >> DateUtil.toString))
                                    || filterOn (v.lastUsedInMeal |> Maybe.andThen .name |> Maybe.withDefault "")
                            )
                        |> List.sortBy (.recipe >> .name)
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.main.pagination
                                    |> Compose.lensWithLens Pagination.lenses.recipeOccurrences
                            }
                            main
            in
            div [ Style.ids.statistics.recipeOccurrence ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.recipesSearchString
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
                                , th [] [ label [] [ text "Date of meal" ] ]
                                , th [] [ label [] [ text "Name of meal" ] ]
                                , th [ Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeOccurrenceLine configuration)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.recipeOccurrences
                                    }
                                    main
                                    >> Page.SetRecipeOccurrencesPagination
                            , elements = viewRecipes
                            }
                        ]
                    ]
                ]


viewRecipeOccurrenceLine : Configuration -> RecipeOccurrence -> Html Page.LogicMsg
viewRecipeOccurrenceLine configuration recipeOccurrence =
    let
        ( mealDate, mealName, mealButton ) =
            recipeOccurrence.lastUsedInMeal
                |> Maybe.Extra.unwrap ( "", "", [] )
                    (\meal ->
                        ( meal.date |> DateUtil.toString
                        , meal.name |> Maybe.withDefault ""
                        , [ td [ Style.classes.controls ]
                                [ NavigationUtil.mealEditorLinkButton configuration meal.id ]
                          ]
                        )
                    )
    in
    tr [ Style.classes.editing ]
        ([ td [ Style.classes.editable ]
            [ label [] [ text recipeOccurrence.recipe.name ] ]
         , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.withDefault "" <| recipeOccurrence.recipe.description ] ]
         , td [ Style.classes.controls ]
            [ label [] [ text mealDate ] ]
         , td [ Style.classes.controls ]
            [ label [] [ text mealName ] ]
         , td [ Style.classes.controls ]
            [ NavigationUtil.recipeNutrientsLinkButton configuration recipeOccurrence.recipe.id ]
         , td [ Style.classes.controls ]
            [ NavigationUtil.recipeEditorLinkButton configuration recipeOccurrence.recipe.id ]
         ]
            ++ mealButton
        )
