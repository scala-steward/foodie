module Pages.Statistics.Meal.Select.View exposing (view)

import Api.Types.TotalOnlyNutrientInformation exposing (TotalOnlyNutrientInformation)
import Dict exposing (Dict)
import Html exposing (Html, div, label, table, tbody, td, text, tr)
import List.Extra
import Maybe.Extra
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.DateUtil as DateUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        model
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = model.authorizedAccess.configuration.mainPageURL
            , currentPage = Nothing
            }
        <|
            let
                viewNutrients =
                    model.mealStats.nutrients
                        |> List.filter (\nutrient -> [ nutrient.base.name, nutrient.base.symbol ] |> List.Extra.find (SearchUtil.search model.statisticsEvaluation.nutrientsSearchString) |> Maybe.Extra.isJust)
            in
            div [ Style.ids.statistics ]
                [ div []
                    [ table [ Style.classes.info ]
                        [ tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Date" ] ]
                            , td [] [ label [] [ text <| Maybe.Extra.unwrap "" (DateUtil.toString << .date) <| model.meal ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Name" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .name <| model.meal ] ]
                            ]
                        ]
                    ]
                , div [ Style.classes.elements ] [ text "Reference map" ]
                , div [ Style.classes.info ]
                    [ StatisticsView.referenceMapDropdownWith
                        { referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , onChange = Page.SelectReferenceMap
                        }
                        model
                    ]
                , div [ Style.classes.elements ] [ text "Nutrients in the meal" ]
                , div [ Style.classes.info, Style.classes.nutrients ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetNutrientsSearchString
                        , searchString = model.statisticsEvaluation.nutrientsSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ StatisticsView.nutrientTableHeader { withDailyAverage = False }
                        , tbody []
                            (List.map
                                (model.statisticsEvaluation.referenceTree
                                    |> Maybe.Extra.unwrap Dict.empty .values
                                    |> StatisticsView.totalOnlyNutrientInformationLine
                                )
                                viewNutrients
                            )
                        ]
                    ]
                ]
