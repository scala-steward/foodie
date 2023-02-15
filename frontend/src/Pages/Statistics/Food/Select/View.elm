module Pages.Statistics.Food.Select.View exposing (view)

import Configuration exposing (Configuration)
import Html exposing (Html, div, label, table, td, text, tr)
import Pages.Statistics.Food.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Uuid


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.Msg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        main
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = configuration.mainPageURL
            , currentPage = Nothing
            }
        <|
            div [ Style.classes.partialStatistics ]
                (div []
                    [ table [ Style.classes.info ]
                        [ tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Food" ] ]
                            , td [] [ label [] [ text <| .name <| main.foodInfo ] ]
                            ]
                        ]
                    ]
                    :: StatisticsView.statisticsTable
                        { onReferenceMapSelection = Maybe.andThen Uuid.fromString >> Page.SelectReferenceMap
                        , onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .foodStats >> .nutrients
                        , amountOf = .amount
                        , dailyAmountOf = .amount
                        , showDailyAmount = False
                        , completenessFraction = Nothing
                        , nutrientBase = .base
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients per 100g"
                        }
                        main
                )
