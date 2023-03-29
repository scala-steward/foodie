module Pages.Util.Choice.ChoiceGroupView exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Util.Choice.ChoiceGroup as ChoiceGroup exposing (IngredientState)
import Pages.Util.Choice.Pagination as Pagination exposing (Pagination)
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
    , info : ingredient -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , controls : ingredient -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , isValidInput : update -> Bool
    , edit : ingredient -> update -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , fitControlsToColumns : Int
    }
    -> ChoiceGroup.Main ingredientId ingredient update foodId food creation
    -> Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation)
viewMain ps main =
    let
        viewIngredientState =
            Editing.unpack
                { onView =
                    viewIngredientLine
                        { idOfIngredient = ps.idOfIngredient
                        , controls = ps.controls
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

        paginatedIngredients =
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
                        ChoiceGroup.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.ingredients
                    }
                    main
    in
    div [ Style.classes.choices ]
        [ HtmlUtil.searchAreaWith
            { msg = ChoiceGroup.SetIngredientsSearchString
            , searchString = main.ingredientsSearchString
            }
        , table [ Style.classes.elementsWithControlsTable, Style.classes.ingredientEditTable ]
            [ thead []
                [ tr [ Style.classes.tableHeader ]
                    [ th [] [ label [] [ text "Name" ] ]
                    , th [ Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
                    , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                    , th [ Style.classes.toggle ] []
                    ]
                ]
            , tbody []
                (paginatedIngredients
                    |> Paginate.page
                    |> List.concatMap viewIngredientState
                )
            ]
        , div [ Style.classes.pagination ]
            [ ViewUtil.pagerButtons
                { msg =
                    PaginationSettings.updateCurrentPage
                        { pagination = ChoiceGroup.lenses.main.pagination
                        , items = Pagination.lenses.ingredients
                        }
                        main
                        >> ChoiceGroup.SetIngredientsPagination
                , elements = paginatedIngredients
                }
            ]
        ]


viewFoods :
    { matchesSearchText : String -> food -> Bool
    , sortBy : food -> comparable
    , foodHeaderColumns : List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , idOfFood : food -> foodId
    , nameOfFood : food -> String
    , ingredientCreationLine : food -> creation -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , ingredientCreationControls : food -> creation -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , viewFoodLine : food -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , viewFoodLineControls : food -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> ChoiceGroup.Main ingredientId ingredient update foodId food creation
    -> Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation)
viewFoods ps main =
    let
        paginatedFoods =
            main
                |> .foods
                |> DictList.values
                |> List.filter (.original >> ps.matchesSearchText main.foodsSearchString)
                |> List.sortBy (.original >> ps.sortBy)
                |> ViewUtil.paginate
                    { pagination =
                        ChoiceGroup.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.foods
                    }
                    main
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = ChoiceGroup.SetFoodsSearchString
                , searchString = main.foodsSearchString
                }
            , table [ Style.classes.elementsWithControlsTable ]
                [ thead []
                    [ tr [ Style.classes.tableHeader ]
                        (ps.foodHeaderColumns
                            ++ [ th [ Style.classes.toggle ] [] ]
                        )
                    ]
                , tbody []
                    (paginatedFoods
                        |> Paginate.page
                        |> List.concatMap
                            (Editing.unpack
                                { onView =
                                    viewFoodLine
                                        { nameOfFood = ps.nameOfFood
                                        , idOfFood = ps.idOfFood
                                        , foodOnView = ps.viewFoodLine
                                        , foodControls = ps.viewFoodLineControls
                                        }
                                , onUpdate =
                                    editIngredientCreation
                                        { idOfFood = ps.idOfFood
                                        , nameOfFood = ps.nameOfFood
                                        , ingredientCreationLine = ps.ingredientCreationLine
                                        , ingredientCreationControls = ps.ingredientCreationControls
                                        }
                                , onDelete = always []
                                }
                            )
                    )
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = ChoiceGroup.lenses.main.pagination
                            , items = Pagination.lenses.foods
                            }
                            main
                            >> ChoiceGroup.SetIngredientsPagination
                    , elements = paginatedFoods
                    }
                ]
            ]
        ]


viewIngredientLine :
    { idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , controls : ingredient -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> ingredient
    -> Bool
    -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
viewIngredientLine ps ingredient showControls =
    ingredientLineWith
        { idOfIngredient = ps.idOfIngredient
        , info = ps.info
        , controls = ps.controls
        , showControls = showControls
        }
        ingredient


deleteIngredientLine :
    { idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> ingredient
    -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
deleteIngredientLine ps =
    ingredientLineWith
        { idOfIngredient = ps.idOfIngredient
        , info = ps.info
        , controls =
            \ingredient ->
                let
                    ingredientId =
                        ingredient |> ps.idOfIngredient
                in
                [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| ChoiceGroup.ConfirmDelete <| ingredientId ] [ text "Delete?" ] ]
                , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick <| ChoiceGroup.CancelDelete <| ingredientId ] [ text "Cancel" ] ]
                ]
        , showControls = True
        }


type alias Column msg =
    { attributes : List (Attribute msg)
    , children : List (Html msg)
    }


withExtraAttributes : List (Attribute msg) -> Column msg -> Html msg
withExtraAttributes extra column =
    td (column.attributes ++ extra) column.children


ingredientLineWith :
    { idOfIngredient : ingredient -> ingredientId
    , info : ingredient -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , controls : ingredient -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , showControls : Bool
    }
    -> ingredient
    -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
ingredientLineWith ps ingredient =
    let
        toggleCommand =
            ChoiceGroup.ToggleControls <| ps.idOfIngredient <| ingredient

        infoColumns =
            ps.info ingredient

        infoCells =
            infoColumns |> List.map (withExtraAttributes [ toggleCommand |> onClick ])

        infoRow =
            tr [ Style.classes.editing ]
                (infoCells
                    ++ [ HtmlUtil.toggleControlsCell toggleCommand ]
                )

        controlsRow =
            tr []
                [ td [ colspan <| List.length <| infoColumns ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] (ps.controls <| ingredient) ] ]
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
    , edit : ingredient -> update -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , fitControlsToColumns : Int
    }
    -> ingredient
    -> update
    -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
editIngredientLine ps ingredient ingredientUpdateClientInput =
    let
        saveMsg =
            ChoiceGroup.SaveEdit ingredientUpdateClientInput

        ingredientId =
            ingredient |> ps.idOfIngredient

        cancelMsg =
            ChoiceGroup.ExitEdit <| ingredientId

        validInput =
            ingredientUpdateClientInput |> ps.isValidInput

        editRow =
            tr [ Style.classes.editLine ]
                ((ps.edit ingredient ingredientUpdateClientInput
                    |> List.map
                        (withExtraAttributes
                            [ onEnter saveMsg
                            , HtmlUtil.onEscape cancelMsg
                            ]
                        )
                 )
                    ++ [ HtmlUtil.toggleControlsCell <| ChoiceGroup.ToggleControls <| ingredientId ]
                )

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


viewFoodLine :
    { nameOfFood : food -> String
    , idOfFood : food -> foodId
    , foodOnView : food -> List (Column (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , foodControls : food -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> food
    -> Bool
    -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
viewFoodLine ps food showControls =
    let
        toggleCommand =
            ChoiceGroup.ToggleFoodControls <| ps.idOfFood <| food

        columns =
            ps.foodOnView food |> List.map (withExtraAttributes [ onClick toggleCommand ])

        infoRow =
            tr [ Style.classes.editing ]
                (td [ Style.classes.editable, onClick toggleCommand ] [ label [] [ text <| ps.nameOfFood <| food ] ]
                    :: (columns ++ [ HtmlUtil.toggleControlsCell toggleCommand ])
                )

        -- Extra column because the name is fixed
        controlsRow =
            tr []
                [ td [ colspan <| (+) 1 <| List.length <| columns ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] (ps.foodControls <| food) ] ]
                ]
    in
    infoRow
        :: (if showControls then
                [ controlsRow ]

            else
                []
           )


editIngredientCreation :
    { idOfFood : food -> foodId
    , nameOfFood : food -> String
    , ingredientCreationLine : food -> creation -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    , ingredientCreationControls : food -> creation -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
    }
    -> food
    -> creation
    -> List (Html (ChoiceGroup.LogicMsg ingredientId ingredient update foodId food creation))
editIngredientCreation ps food creation =
    let
        foodId =
            food |> ps.idOfFood

        toggleMsg =
            ChoiceGroup.ToggleFoodControls <| foodId

        creationRow =
            tr []
                (td [ Style.classes.editable ] [ label [] [ text <| ps.nameOfFood <| food ] ]
                    :: ps.ingredientCreationLine food creation
                    ++ [ HtmlUtil.toggleControlsCell <| toggleMsg ]
                )

        columns =
            ps.ingredientCreationLine food creation

        -- Extra column because the name is fixed
        controlsRow =
            tr []
                [ td [ colspan <| (+) 1 <| List.length <| columns ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr []
                            (ps.ingredientCreationControls food creation)
                        ]
                    ]
                ]
    in
    [ creationRow, controlsRow ]
