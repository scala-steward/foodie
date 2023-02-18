module Pages.Statistics.Recipe.Select.View exposing (view)

import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Html, div, label, table, td, text, tr)
import Pages.Statistics.Recipe.Select.Page as Page
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


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
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
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Recipe" ] ]
                            , td [] [ label [] [ text <| .name <| main.recipe ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Description" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| .description <| main.recipe ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Weight of ingredients" ] ]
                            , td [] [ label [] [ text <| flip (++) "g" <| StatisticsView.displayFloat <| .weightInGrams <| main.recipeStats ] ]
                            ]
                        ]
                    ]
                    :: StatisticsView.referenceMapSelection
                        { onReferenceMapSelection = Maybe.andThen Uuid.fromString >> Page.SelectReferenceMap
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        }
                        main
                    ++ StatisticsView.statisticsTable
                        { onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .recipeStats >> .nutrients
                        , amountOf = .amount >> .value
                        , dailyAmountOf = .amount >> .value
                        , showDailyAmount = False
                        , completenessFraction =
                            Just
                                { definedValues = .amount >> .numberOfDefinedValues
                                , totalValues = .amount >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients per serving"
                        }
                        main
                )
