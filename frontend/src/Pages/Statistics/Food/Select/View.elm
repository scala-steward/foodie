module Pages.Statistics.Food.Select.View exposing (view)

import Api.Types.FoodNutrientInformation exposing (FoodNutrientInformation)
import Dict exposing (Dict)
import Html exposing (Html, div, label, table, tbody, td, text, tr)
import List.Extra
import Maybe.Extra
import Pages.Statistics.Food.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
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
                    model.foodStats.nutrients
                        |> List.filter (\nutrient -> [ nutrient.base.name, nutrient.base.symbol ] |> List.Extra.find (SearchUtil.search model.statisticsEvaluation.nutrientsSearchString) |> Maybe.Extra.isJust)
            in
            div [ Style.ids.statistics ]
                [ div []
                    [ table [ Style.classes.info ]
                        [ tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Food" ] ]
                            , td [] [ label [] [ text <| .name <| model.foodInfo ] ]
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
                , div [ Style.classes.elements ] [ text "Nutrients per 100g" ]
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
                                    |> StatisticsView.foodNutrientInformationLine
                                )
                                viewNutrients
                            )
                        ]
                    ]
                ]
