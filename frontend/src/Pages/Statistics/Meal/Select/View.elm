module Pages.Statistics.Meal.Select.View exposing (view)

import Html exposing (Html, div, label, table, td, text, tr)
import Maybe.Extra
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


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
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Date" ] ]
                            , td [] [ label [] [ text <| Maybe.Extra.unwrap "" (DateUtil.toString << .date) <| model.meal ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Name" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .name <| model.meal ] ]
                            ]
                        ]
                    ]
                    :: StatisticsView.statisticsTable
                        { onReferenceMapSelection = Page.SelectReferenceMap
                        , onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .mealStats >> .nutrients
                        , amountOf = .amount >> .value
                        , dailyAmountOf = Just (.amount >> .value)
                        , completenessFraction =
                            Just
                                { definedValues = .amount >> .numberOfDefinedValues
                                , totalValues = .amount >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients in the meal"
                        }
                        model
                )
