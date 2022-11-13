module Pages.Statistics.StatisticsView exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant
import FormatNumber
import FormatNumber.Locales
import Html exposing (Attribute, Html, div)
import Maybe.Extra
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
