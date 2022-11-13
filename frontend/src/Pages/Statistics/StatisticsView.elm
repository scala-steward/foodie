module Pages.Statistics.StatisticsView exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (NutrientCode, ReferenceMapId)
import Api.Types.FoodNutrientInformation exposing (FoodNutrientInformation)
import Api.Types.NutrientInformationBase exposing (NutrientInformationBase)
import Api.Types.NutrientUnit as NutrientUnit
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Api.Types.TotalOnlyNutrientInformation exposing (TotalOnlyNutrientInformation)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Dropdown exposing (dropdown)
import FormatNumber
import FormatNumber.Locales
import Html exposing (Attribute, Html, div, label, td, text, th, thead, tr)
import Maybe.Extra
import Pages.Statistics.StatisticsUtil exposing (ReferenceNutrientTree)
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


displayFloat : Float -> String
displayFloat =
    FormatNumber.format FormatNumber.Locales.frenchLocale


quotientInfo :
    { defined : Int
    , total : Int
    , value : Maybe a
    }
    -> String
quotientInfo ps =
    [ ps.defined, ps.total ]
        |> List.map String.fromInt
        |> String.join "/"
        |> Just
        |> Maybe.Extra.filter (\_ -> ps.value |> Maybe.Extra.isJust)
        |> Maybe.Extra.unwrap "" (\v -> [ " ", "(", v, ")" ] |> String.join "")


referenceFactor :
    { actualValue : Maybe Float
    , referenceValue : Maybe Float
    }
    -> Maybe Float
referenceFactor vs =
    vs.referenceValue
        |> Maybe.Extra.filter (\x -> x > 0)
        |> Maybe.andThen
            (\r ->
                vs.actualValue |> Maybe.map (\a -> 100 * (a / r))
            )


factorStyle : Maybe Float -> List (Attribute msg)
factorStyle factor =
    Maybe.Extra.unwrap []
        (\percent ->
            [ if percent > 100 then
                Style.classes.rating.high

              else if percent == 100 then
                Style.classes.rating.exact

              else
                Style.classes.rating.low
            ]
        )
        factor


navigationBar :
    { mainPageURL : String
    , currentPage : Maybe StatisticsVariant.Page
    }
    -> Html msg
navigationBar ps =
    ViewUtil.navigationBarWith
        { navigationPages = navigationPages
        , pageToButton =
            \page ->
                ViewUtil.navigationToPageButtonWith
                    { page = page
                    , nameOf = StatisticsVariant.nameOfPage
                    , addressSuffix = StatisticsVariant.addressSuffix
                    , mainPageURL = ps.mainPageURL
                    , currentPage = ps.currentPage
                    }
        }


navigationPages : List StatisticsVariant.Page
navigationPages =
    [ StatisticsVariant.Food
    , StatisticsVariant.Recipe
    , StatisticsVariant.Meal
    , StatisticsVariant.Time
    ]


withNavigationBar :
    { mainPageURL : String
    , currentPage : Maybe StatisticsVariant.Page
    }
    -> Html msg
    -> Html msg
withNavigationBar ps html =
    div []
        [ navigationBar ps
        , html
        ]


nutrientInformationLineWith :
    { amountOf : information -> Maybe Float
    , nutrientBase : information -> NutrientInformationBase
    }
    -> Dict NutrientCode Float
    -> information
    -> Html msg
nutrientInformationLineWith ps referenceValues information =
    let
        referenceValue =
            Dict.get (ps.nutrientBase information).nutrientCode referenceValues

        factor =
            referenceFactor
                { actualValue = ps.amountOf information
                , referenceValue = referenceValue
                }

        displayValue =
            Maybe.Extra.unwrap "" displayFloat
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| .name <| ps.nutrientBase <| information ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| displayValue <| ps.amountOf <| information ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| displayValue <| referenceValue ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| NutrientUnit.toString <| .unit <| ps.nutrientBase <| information ] ]
        , td [ Style.classes.numberCell ]
            [ label (factorStyle factor)
                [ text <|
                    Maybe.Extra.unwrap "" (displayFloat >> flip (++) "%") <|
                        factor
                ]
            ]
        ]


totalOnlyNutrientInformationLine : Dict NutrientCode Float -> TotalOnlyNutrientInformation -> Html msg
totalOnlyNutrientInformationLine =
    nutrientInformationLineWith
        { amountOf = .amount >> .value
        , nutrientBase = .base
        }


foodNutrientInformationLine : Dict NutrientCode Float -> FoodNutrientInformation -> Html msg
foodNutrientInformationLine =
    nutrientInformationLineWith
        { amountOf = .amount
        , nutrientBase = .base
        }


nutrientTableHeader : { withDailyAverage : Bool } -> Html msg
nutrientTableHeader ps =
    let
        dailyAverageColumn =
            if ps.withDailyAverage then
                [ th [ Style.classes.numberLabel ] [ label [] [ text "Daily average" ] ] ]

            else
                []
    in
    thead []
        [ tr [ Style.classes.tableHeader ]
            ([ th [] [ label [] [ text "Name" ] ]
             , th [ Style.classes.numberLabel ] [ label [] [ text "Total" ] ]
             ]
                ++ dailyAverageColumn
                ++ [ th [ Style.classes.numberLabel ] [ label [] [ text "Reference daily average" ] ]
                   , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                   , th [ Style.classes.numberLabel ] [ label [] [ text "Percentage" ] ]
                   ]
            )
        ]


referenceMapDropdownWith :
    { referenceTrees : model -> Dict ReferenceMapId ReferenceNutrientTree
    , referenceTree : model -> Maybe ReferenceNutrientTree
    , onChange : Maybe ReferenceMapId -> msg
    }
    -> model
    -> Html msg
referenceMapDropdownWith ps model =
    dropdown
        { items =
            model
                |> ps.referenceTrees
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
        , onChange = ps.onChange
        }
        []
        (model |> ps.referenceTree |> Maybe.map (.map >> .id))
