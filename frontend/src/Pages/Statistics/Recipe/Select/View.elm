module Pages.Statistics.Recipe.Select.View exposing (view)

import Html exposing (Html, div, label, table, td, text, tr)
import Pages.Statistics.Recipe.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
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
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Recipe" ] ]
                            , td [] [ label [] [ text <| .name <| model.recipe ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Description" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| .description <| model.recipe ] ]
                            ]
                        ]
                    ]
                    :: StatisticsView.statisticsTable
                        { onReferenceMapSelection = Page.SelectReferenceMap
                        , onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .recipeStats >> .nutrients
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
                        , tableLabel = "Nutrients per serving"
                        }
                        model
                )
