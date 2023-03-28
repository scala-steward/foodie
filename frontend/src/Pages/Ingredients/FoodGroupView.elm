module Pages.Ingredients.FoodGroupView exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled)
import Html.Events exposing (onClick)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Ingredients.FoodGroup as FoodGroup exposing (IngredientState)
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate exposing (PaginatedList)
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewMain :
    { nameOfFood : food -> String
    , foodIdOfIngredient : ingredient -> foodId
    , idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , isValidInput : update -> Bool
    , edit : ingredient -> List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , fitControlsToColumns : Int
    }
    -> FoodGroup.Main ingredientId ingredient update foodId food creation
    -> Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation)
viewMain ps main =
    let
        viewIngredientState =
            Editing.unpack
                { onView =
                    viewIngredientLine
                        { idOfIngredient = ps.idOfIngredient
                        , info = ps.info
                        }
                , onUpdate =
                    editIngredientLine
                        { idOfIngredient = ps.idOfIngredient
                        , isValidInput = ps.isValidInput
                        , edit = ps.edit
                        , fitControlsToColumns = ps.fitControlsToColumns
                        }
                , onDelete =
                    deleteIngredientLine
                        { idOfIngredient = ps.idOfIngredient
                        , info = ps.info
                        }
                }

        extractedName =
            .original
                >> ps.foodIdOfIngredient
                >> flip DictList.get main.foods
                >> Maybe.Extra.unwrap "" (.original >> ps.nameOfFood)

        viewIngredients =
            main
                |> .ingredients
                |> DictList.values
                |> List.filter
                    (extractedName
                        >> SearchUtil.search main.ingredientsSearchString
                    )
                |> List.sortBy
                    (extractedName
                        >> String.toLower
                    )
                |> ViewUtil.paginate
                    { pagination =
                        FoodGroup.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.ingredients
                    }
                    main
    in
    div [ Style.classes.choices ]
        [ HtmlUtil.searchAreaWith
            { msg = FoodGroup.SetIngredientsSearchString
            , searchString = main.ingredientsSearchString
            }
        , table [ Style.classes.elementsWithControlsTable, Style.classes.ingredientEditTable ]
            [ colgroup []
                [ col [] []
                , col [] []
                , col [] []
                , col [] []
                ]
            , thead []
                [ tr [ Style.classes.tableHeader ]
                    [ th [] [ label [] [ text "Name" ] ]
                    , th [ Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
                    , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                    , th [ Style.classes.toggle ] []
                    ]
                ]
            , tbody []
                (viewIngredients
                    |> Paginate.page
                    |> List.concatMap viewIngredientState
                )
            ]
        , div [ Style.classes.pagination ]
            [ ViewUtil.pagerButtons
                { msg =
                    PaginationSettings.updateCurrentPage
                        { pagination = FoodGroup.lenses.main.pagination
                        , items = Pagination.lenses.ingredients
                        }
                        main
                        >> FoodGroup.SetIngredientsPagination
                , elements = viewIngredients
                }
            ]
        ]


viewFoods =
    div [] []


viewIngredientLine :
    { idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> ingredient
    -> Bool
    -> List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
viewIngredientLine ps ingredient showControls =
    let
        ingredientId =
            ingredient |> ps.idOfIngredient

        editMsg =
            ingredientId |> FoodGroup.EnterEdit |> onClick
    in
    ingredientLineWith
        { idOfIngredient = ps.idOfIngredient
        , info = ps.info
        , controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| FoodGroup.RequestDelete <| ingredientId ] [ text "Delete" ] ]
            ]
        , showControls = showControls
        }
        ingredient


deleteIngredientLine :
    { idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> ingredient
    -> List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
deleteIngredientLine ps ingredient =
    let
        ingredientId =
            ingredient |> ps.idOfIngredient
    in
    ingredientLineWith
        { idOfIngredient = ps.idOfIngredient
        , info = ps.info
        , controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| FoodGroup.ConfirmDelete <| ingredientId ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick <| FoodGroup.CancelDelete <| ingredientId ] [ text "Cancel" ] ]
            ]
        , showControls = True
        }
        ingredient


type alias Column msg =
    { attributes : List (Attribute msg)
    , children : List (Html msg)
    }


ingredientLineWith :
    { idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , controls : List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , showControls : Bool
    }
    -> ingredient
    -> List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
ingredientLineWith ps ingredient =
    let
        toggleCommand =
            FoodGroup.ToggleControls <| ps.idOfIngredient <| ingredient

        withOnClick =
            (::) (toggleCommand |> onClick)

        infoColumns =
            ps.info ingredient

        infoCells =
            infoColumns |> List.map (\c -> td (c.attributes |> withOnClick) c.children)

        infoRow =
            tr [ Style.classes.editing ]
                (infoCells
                    ++ [ HtmlUtil.toggleControlsCell toggleCommand ]
                )

        controlsRow =
            tr []
                [ td [ colspan <| List.length <| infoColumns ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] ps.controls ] ]
                ]
    in
    infoRow
        :: (if ps.showControls then
                [ controlsRow ]

            else
                []
           )


editIngredientLine :
    { idOfIngredient : ingredient -> ingredientId
    , isValidInput : update -> Bool
    , edit : ingredient -> List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , fitControlsToColumns : Int
    }
    -> ingredient
    -> update
    -> List (Html (FoodGroup.LogicMsg ingredientId ingredient update foodId food creation))
editIngredientLine ps ingredient ingredientUpdateClientInput =
    let
        saveMsg =
            FoodGroup.SaveEdit ingredientUpdateClientInput

        ingredientId =
            ingredient |> ps.idOfIngredient

        cancelMsg =
            FoodGroup.ExitEdit <| ingredientId

        validInput =
            ingredientUpdateClientInput |> ps.isValidInput

        editRow =
            tr [ Style.classes.editLine ] ((ingredient |> ps.edit) ++ [ HtmlUtil.toggleControlsCell <| FoodGroup.ToggleControls <| ingredientId ])

        controlsRow =
            tr []
                [ td [ colspan <| ps.fitControlsToColumns ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr []
                            [ td [ Style.classes.controls ]
                                [ button
                                    ([ MaybeUtil.defined <| Style.classes.button.confirm
                                     , MaybeUtil.defined <| disabled <| not <| validInput
                                     , MaybeUtil.optional validInput <| onClick saveMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    [ text <| "Save" ]
                                ]
                            , td [ Style.classes.controls ]
                                [ button [ Style.classes.button.cancel, onClick cancelMsg ]
                                    [ text <| "Cancel" ]
                                ]
                            ]
                        ]
                    ]
                ]
    in
    [ editRow, controlsRow ]
