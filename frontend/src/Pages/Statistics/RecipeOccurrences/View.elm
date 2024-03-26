module Pages.Statistics.RecipeOccurrences.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.RecipeOccurrence exposing (RecipeOccurrence)
import Configuration exposing (Configuration)
import Html exposing (Html, button, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
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
            , currentPage = Just StatisticsVariant.RecipeOccurrences
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
                                    || filterOn (v.lastUsedInMeal |> Maybe.Extra.unwrap "" (.date >> DateUtil.toPrettyString))
                                    || filterOn (v.lastUsedInMeal |> Maybe.andThen .name |> Maybe.withDefault "")
                            )
                        |> sortBy main.sortType
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
                    , div [ Style.classes.sortControls ]
                        [ label [] [ text "Sort by" ]
                        , button
                            [ disabled <| main.sortType == Page.RecipeName
                            , onClick (Page.SortBy Page.RecipeName)
                            , Style.classes.button.alternative
                            ]
                            [ label [] [ text "Recipe name" ] ]
                        , button
                            [ disabled <| main.sortType == Page.MealDate
                            , onClick (Page.SortBy Page.MealDate)
                            , Style.classes.button.alternative
                            ]
                            [ label [] [ text "Meal date" ] ]
                        ]
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Recipe" ] ]
                                , th [] [ label [] [ text "Description" ] ]
                                , th [] [ label [] [ text "Meal date" ] ]
                                , th [] [ label [] [ text "Meal name" ] ]
                                , th [] []
                                , th [] []
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
                        ( meal.date |> DateUtil.toPrettyString
                        , meal.name |> Maybe.withDefault ""
                        , [ td [ Style.classes.controls ]
                                -- todo identity: fix me
                                [ NavigationUtil.mealEditorLinkButton configuration meal.id meal.id ]
                          ]
                        )
                    )
    in
    tr [ Style.classes.editLine ]
        ([ td [ Style.classes.editable ]
            [ label [] [ text recipeOccurrence.recipe.name ] ]
         , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.withDefault "" <| recipeOccurrence.recipe.description ] ]
         , td [ Style.classes.editable ]
            [ label [] [ text mealDate ] ]
         , td [ Style.classes.editable ]
            [ label [] [ text mealName ] ]
         , td [ Style.classes.editable ]
            [ NavigationUtil.recipeEditorLinkButton configuration recipeOccurrence.recipe.id ]
         ]
            ++ mealButton
        )


sortBy : Page.SortType -> List RecipeOccurrence -> List RecipeOccurrence
sortBy sortType recipeOccurrences =
    case sortType of
        Page.RecipeName ->
            recipeOccurrences
                |> List.sortBy (.recipe >> .name)

        Page.MealDate ->
            recipeOccurrences
                |> List.sortBy (.lastUsedInMeal >> Maybe.Extra.unwrap "" (.date >> DateUtil.toPrettyString))
                |> List.reverse
