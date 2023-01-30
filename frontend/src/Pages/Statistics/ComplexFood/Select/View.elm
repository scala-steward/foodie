module Pages.Statistics.ComplexFood.Select.View exposing (view)

import Basics.Extra exposing (flip)
import Html exposing (Html, div, label, table, td, text, tr)
import Pages.Statistics.ComplexFood.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Uuid


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
            div [ Style.classes.partialStatistics ]
                (div []
                    [ table [ Style.classes.info ]
                        [ tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Complex food" ] ]
                            , td [] [ label [] [ text <| .name <| model.complexFood ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Description" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| .description <| model.complexFood ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Set weight" ] ]
                            , td [] [ label [] [ text <| flip (++) "g" <| StatisticsView.displayFloat <| .amountGrams <| model.complexFood ] ]
                            ]
                        ]
                    ]
                    :: StatisticsView.statisticsTable
                        { onReferenceMapSelection = Maybe.andThen Uuid.fromString >> Page.SelectReferenceMap
                        , onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .foodStats >> .nutrients
                        , amountOf = .amount >> .value
                        , dailyAmountOf = .amount >> .value
                        , showDailyAmount = False
                        , completenessFraction =
                            Just
                                { definedValues = .amount >> .numberOfDefinedValues
                                , totalValues = .amount >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients per 100g"
                        }
                        model
                )
