module Pages.Util.ViewUtil exposing (Page(..), navigationBarWith, navigationToPageButton, navigationToPageButtonWith, pagerButtons, paginate, viewWithErrorHandling, viewWithErrorHandlingSimple)

import Api.Auxiliary exposing (JWT)
import Api.Types.LoginContent exposing (decoderLoginContent)
import Configuration exposing (Configuration)
import Html exposing (Html, button, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
import Jwt
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)
import Pages.Util.Style as Style
import Paginate exposing (PaginatedList)
import Url.Builder
import Util.Initialization exposing (Initialization(..))
import Util.MaybeUtil as MaybeUtil


viewWithErrorHandling :
    { isFinished : status -> Bool
    , initialization : model -> Initialization status
    , configuration : model -> Configuration
    , jwt : model -> Maybe JWT
    , currentPage : Maybe Page
    , showNavigation : Bool
    }
    -> model
    -> Html msg
    -> Html msg
viewWithErrorHandling params model html =
    let
        mainPageURL =
            model |> params.configuration |> .mainPageURL
    in
    case params.initialization model of
        Failure explanation ->
            let
                solutionBlock =
                    if explanation.possibleSolution |> String.isEmpty then
                        []

                    else
                        [ td [] [ label [] [ text "Try the following:" ] ]
                        , td [] [ label [] [ text <| explanation.possibleSolution ] ]
                        ]

                redirectBlock =
                    [ td []
                        [ navigationToPageButton
                            { page = Login
                            , mainPageURL = mainPageURL
                            , currentPage = Nothing
                            }
                        ]
                    ]
                        |> List.filter (always explanation.redirectToLogin)
            in
            div [ Style.ids.error ]
                [ tr []
                    [ td [] [ label [] [ text "An error occurred:" ] ]
                    , td [] [ label [] [ text <| explanation.cause ] ]
                    ]
                , tr [] solutionBlock
                , tr [] redirectBlock
                ]

        Loading status ->
            if params.isFinished status then
                let
                    unknown =
                        "<unknown>"

                    nickname =
                        model
                            |> params.jwt
                            |> Maybe.andThen
                                (Jwt.decodeToken decoderLoginContent
                                    >> Result.toMaybe
                                )
                            |> Maybe.Extra.unwrap unknown .nickname

                    navigation =
                        [ navigationBar
                            { mainPageURL = mainPageURL
                            , currentPage = params.currentPage
                            , nickname = nickname
                            }
                        ]
                            |> List.filter (always params.showNavigation)
                in
                div []
                    (navigation
                        ++ [ html ]
                    )

            else
                div [] [ Links.loadingSymbol ]


viewWithErrorHandlingSimple :
    { configuration : Configuration
    , jwt : main -> Maybe JWT
    , currentPage : Maybe Page
    , showNavigation : Bool
    }
    -> main
    -> Html msg
    -> Html msg
viewWithErrorHandlingSimple params model html =
    let
        unknown =
            "<unknown>"

        navigation =
            [ navigationBar
                { mainPageURL = params.configuration |> .mainPageURL
                , currentPage = params.currentPage
                , nickname =
                    model
                        |> params.jwt
                        |> Maybe.andThen
                            (Jwt.decodeToken decoderLoginContent
                                >> Result.toMaybe
                            )
                        |> Maybe.Extra.unwrap unknown .nickname
                }
            ]
                |> List.filter (always params.showNavigation)
    in
    div []
        (navigation
            ++ [ html ]
        )


type Page
    = Recipes
    | Meals
    | Statistics
    | ReferenceMaps
    | UserSettings String
    | Login
    | Overview
    | ComplexFoods


navigationPages : String -> List Page
navigationPages nickname =
    [ Recipes, Meals, ComplexFoods, Statistics, ReferenceMaps, UserSettings nickname ]



-- todo: Use real addresses


addressSuffix : Page -> String
addressSuffix page =
    case page of
        Recipes ->
            "recipes"

        Meals ->
            "meals"

        Statistics ->
            "statistics"

        ReferenceMaps ->
            "reference-maps"

        UserSettings _ ->
            "user-settings"

        Login ->
            "login"

        Overview ->
            "overview"

        ComplexFoods ->
            "complex-foods"


nameOf : Page -> String
nameOf page =
    case page of
        Recipes ->
            "Recipes"

        Meals ->
            "Meals"

        Statistics ->
            "Statistics"

        ReferenceMaps ->
            "Reference maps"

        UserSettings nickname ->
            nickname

        Login ->
            "Login"

        Overview ->
            "Overview"

        ComplexFoods ->
            "Complex foods"


navigationLink : { mainPageURL : String, page : String } -> String
navigationLink ps =
    Url.Builder.relative
        [ ps.mainPageURL
        , "#"
        , ps.page
        ]
        []


navigationToPageButton :
    { page : Page
    , mainPageURL : String
    , currentPage : Maybe Page
    }
    -> Html msg
navigationToPageButton ps =
    navigationToPageButtonWith
        { page = ps.page
        , nameOf = nameOf
        , addressSuffix = addressSuffix
        , mainPageURL = ps.mainPageURL
        , currentPage = ps.currentPage
        }


navigationToPageButtonWith :
    { page : page
    , nameOf : page -> String
    , addressSuffix : page -> String
    , mainPageURL : String
    , currentPage : Maybe page
    }
    -> Html msg
navigationToPageButtonWith ps =
    let
        isDisabled =
            Maybe.Extra.unwrap False (\current -> current == ps.page) ps.currentPage
    in
    if isDisabled then
        button
            [ Style.classes.button.navigation
            , Style.classes.disabled
            , disabled True
            ]
            [ text <| ps.nameOf <| ps.page ]

    else
        Links.linkButton
            { url =
                navigationLink
                    { mainPageURL = ps.mainPageURL
                    , page = ps.addressSuffix ps.page
                    }
            , attributes = [ Style.classes.button.navigation ]
            , children = [ text <| ps.nameOf <| ps.page ]
            }


navigationBar :
    { mainPageURL : String
    , currentPage : Maybe Page
    , nickname : String
    }
    -> Html msg
navigationBar ps =
    navigationBarWith
        { navigationPages = navigationPages ps.nickname
        , pageToButton =
            \page ->
                navigationToPageButton
                    { page = page
                    , mainPageURL = ps.mainPageURL
                    , currentPage = ps.currentPage
                    }
        }


navigationBarWith :
    { navigationPages : List page
    , pageToButton : page -> Html msg
    }
    -> Html msg
navigationBarWith ps =
    div [ Style.ids.navigation ]
        [ table []
            [ thead []
                [ tr []
                    (ps.navigationPages
                        |> List.map
                            (\page ->
                                th []
                                    [ ps.pageToButton page
                                    ]
                            )
                    )
                ]
            ]
        ]


pagerButtons :
    { msg : Int -> msg
    , elements : PaginatedList a
    }
    -> Html msg
pagerButtons ps =
    let
        pagerButton pageNum isCurrentPage =
            button
                ([ MaybeUtil.defined <| Style.classes.button.pager
                 , MaybeUtil.defined <| onClick <| ps.msg <| pageNum
                 , MaybeUtil.optional isCurrentPage <| disabled <| True
                 , MaybeUtil.optional isCurrentPage <| Style.classes.disabled
                 ]
                    |> Maybe.Extra.values
                )
                [ text <| String.fromInt pageNum
                ]

        cells =
            Paginate.elidedPager
                { innerWindow = 5
                , outerWindow = 1
                , pageNumberView = pagerButton
                , gapView = button [ Style.classes.ellipsis ] [ text "..." ]
                }
                ps.elements
                |> List.map (\elt -> td [] [ elt ])
                |> List.filter (Paginate.totalPages ps.elements > 1 |> always)
    in
    table []
        [ tbody []
            [ tr []
                cells
            ]
        ]


paginate :
    { pagination : Lens model PaginationSettings
    }
    -> model
    -> List a
    -> PaginatedList a
paginate ps model =
    Paginate.fromList ((ps.pagination |> Compose.lensWithLens PaginationSettings.lenses.itemsPerPage).get model)
        >> Paginate.goTo (model |> (ps.pagination |> Compose.lensWithLens PaginationSettings.lenses.currentPage).get)
