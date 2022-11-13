module Pages.Statistics.Food.Select.View exposing (view)

import Api.Auxiliary exposing (NutrientCode)
import Api.Types.FoodNutrientInformation exposing (FoodNutrientInformation)
import Api.Types.NutrientUnit as NutrientUnit
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Dropdown exposing (dropdown)
import Html exposing (Html, div, label, table, tbody, td, text, th, thead, tr)
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
        , currentPage = Nothing --todo: Decide on correct navigation
        , showNavigation = True
        }
        model
    <|
        let
            viewNutrients =
                model.foodStats.nutrients
                    |> List.filter (\nutrient -> [ nutrient.base.name, nutrient.base.symbol ] |> List.Extra.find (SearchUtil.search model.statisticsEvaluation.nutrientsSearchString) |> Maybe.Extra.isJust)
                    |> List.sortBy (.base >> .name)
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
                [ dropdown
                    { items =
                        model.statisticsEvaluation.referenceTrees
                            |> Dict.toList
                            |> List.sortBy (Tuple.second >> .map >> .name)
                            |> List.map
                                (\( referenceMapId, referenceTree ) ->
                                    { value = referenceMapId
                                    , text = referenceTree.map.name
                                    , enabled = True
                                    }
                                )
                    , emptyItem =
                        Just
                            { value = ""
                            , text = ""
                            , enabled = True
                            }
                    , onChange = Page.SelectReferenceMap
                    }
                    []
                    (model.statisticsEvaluation.referenceTree |> Maybe.map (.map >> .id))
                ]
            , div [ Style.classes.elements ] [ text "Nutrients per 100g" ]
            , div [ Style.classes.info, Style.classes.nutrients ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetNutrientsSearchString
                    , searchString = model.statisticsEvaluation.nutrientsSearchString
                    }
                , table []
                    [ thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [] [ label [] [ text "Name" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Total" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Reference daily average" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Percentage" ] ]
                            ]
                        ]
                    , tbody [] (List.map (model.statisticsEvaluation.referenceTree |> Maybe.Extra.unwrap Dict.empty .values |> nutrientInformationLine) viewNutrients)
                    ]
                ]
            ]


nutrientInformationLine : Dict NutrientCode Float -> FoodNutrientInformation -> Html Page.Msg
nutrientInformationLine referenceValues foodNutrientInformation =
    let
        referenceValue =
            Dict.get foodNutrientInformation.base.nutrientCode referenceValues

        factor =
            StatisticsView.referenceFactor
                { actualValue = foodNutrientInformation.amount
                , referenceValue = referenceValue
                }

        factorStyle =
            factor |> StatisticsView.factorStyle

        displayValue =
            Maybe.Extra.unwrap "" StatisticsView.displayFloat
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| foodNutrientInformation.base.name ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| displayValue <| foodNutrientInformation.amount ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| displayValue <| referenceValue ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| NutrientUnit.toString <| foodNutrientInformation.base.unit ] ]
        , td [ Style.classes.numberCell ]
            [ label factorStyle
                [ text <|
                    Maybe.Extra.unwrap "" (StatisticsView.displayFloat >> flip (++) "%") <|
                        factor
                ]
            ]
        ]
