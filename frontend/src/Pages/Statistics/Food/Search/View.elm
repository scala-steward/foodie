module Pages.Statistics.Food.Search.View exposing (view)

import Addresses.Frontend
import Api.Types.Food exposing (Food)
import Configuration exposing (Configuration)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, scope)
import Html.Attributes.Extra exposing (stringProperty)
import Monocle.Compose as Compose
import Pages.Statistics.Food.Search.Page as Page
import Pages.Statistics.Food.Search.Pagination as Pagination
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    let
        viewFoods =
            model.foods
                |> List.filter (\v -> SearchUtil.search model.foodsSearchString v.name)
                |> List.sortBy .name
                |> ViewUtil.paginate
                    { pagination =
                        Page.lenses.pagination
                            |> Compose.lensWithLens Pagination.lenses.foods
                    }
                    model
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = Page.SetSearchString
                , searchString = model.foodsSearchString
                }
            , table [ Style.classes.choiceTable ]
                [ colgroup []
                    [ col [] []
                    , col [ stringProperty "span" "2" ] []
                    ]
                , thead []
                    [ tr [ Style.classes.tableHeader ]
                        [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                        , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                        ]
                    ]
                , tbody []
                    (viewFoods
                        |> Paginate.page
                        |> List.map (viewFoodLine model.authorizedAccess.configuration)
                    )
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.pagination
                            , items = Pagination.lenses.foods
                            }
                            model
                            >> Page.SetFoodsPagination
                    , elements = viewFoods
                    }
                ]
            ]
        ]


viewFoodLine : Configuration -> Food -> Html Page.Msg
viewFoodLine configuration food =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text food.name ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsFoodSelect.address <| food.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Nutrients" ]
                    }
                ]
            ]
        ]
