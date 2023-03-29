module Pages.Ingredients.Complex.View exposing (viewFoods, viewMain)

import Api.Types.ComplexFood exposing (ComplexFood)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra
import Pages.Ingredients.Complex.Page as Page
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput
import Pages.Ingredients.FoodGroup as FoodGroup
import Pages.Ingredients.FoodGroupView as FoodGroupView
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    FoodGroupView.viewMain
        { nameOfFood = .name
        , foodIdOfIngredient = .complexFoodId
        , idOfIngredient = .complexFoodId
        , info =
            \complexIngredient ->
                let
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.foods |> Maybe.map .original

                    amountInfo =
                        complexFood
                            |> Maybe.Extra.unwrap "" amountInfoOf
                in
                [ { attributes = [ Style.classes.editable ], children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ] }
                , { attributes = [ Style.classes.editable, Style.classes.numberLabel ], children = [ label [] [ text <| String.fromFloat <| complexIngredient.factor ] ] }
                , { attributes = [ Style.classes.editable, Style.classes.numberLabel ], children = [ label [] [ text <| amountInfo ] ] }
                ]
        , controls =
            \complexIngredient ->
                let
                    editMsg =
                        FoodGroup.EnterEdit complexIngredient.complexFoodId |> onClick
                in
                [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
                , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (FoodGroup.RequestDelete complexIngredient.complexFoodId) ] [ text "Delete" ] ]
                , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexIngredient.complexFoodId ]
                ]
        , isValidInput = .factor >> ValidatedInput.isValid
        , edit =
            \complexIngredient complexIngredientUpdateClientInput ->
                let
                    -- todo: Flatten maybes
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.foods |> Maybe.map .original
                in
                [ { attributes = []
                  , children =
                        [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value
                                complexIngredientUpdateClientInput.factor.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexIngredientClientInput.lenses.factor
                                    ).set
                                    complexIngredientUpdateClientInput
                                    >> FoodGroup.Edit
                                )
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ label [ Style.classes.editable, Style.classes.numberLabel ] [ text <| Maybe.Extra.unwrap "" amountInfoOf <| complexFood ]
                        ]
                  }
                ]
        , fitControlsToColumns = 3
        }
        main

-- Todo: Controls for the selection case are missing
viewFoods : Configuration -> Page.Main -> Html Page.LogicMsg
viewFoods configuration main =
    let
        ( factor, amount ) =
            if DictListUtil.existsValue Editing.isUpdate main.foods then
                ( "Factor", "Amount" )

            else
                ( "", "" )
    in
    FoodGroupView.viewFoods
        { matchesSearchText = \string -> .name >> SearchUtil.search string
        , sortBy = .name
        , foodHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text factor ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amount ] ]
            ]
        , nameOfFood = .name
        , elementsIfSelected =
            \complexFood creation ->
                let
                    validInput =
                        List.all identity
                            [ creation.factor |> ValidatedInput.isValid
                            ]
                in
                -- todo: Validation is missing!
                [ td [ Style.classes.numberCell ]
                    [ input
                        [ value creation.factor.text
                        , onInput
                            (flip
                                (ValidatedInput.lift
                                    ComplexIngredientClientInput.lenses.factor
                                ).set
                                creation
                                >> FoodGroup.UpdateCreation
                            )
                        , Style.classes.numberLabel
                        ]
                        []
                    ]
                , td [ Style.classes.editable, Style.classes.numberLabel, onClick <| FoodGroup.SelectFood <| complexFood ] [ label [] [ text <| amountInfoOf <| complexFood ] ]
                ]
        , elementsIfNotSelected =
            \complexFood ->
                let
                    exists =
                        DictListUtil.existsValue (\complexIngredient -> complexIngredient.original.complexFoodId == complexFood.recipeId) main.ingredients

                    ( selectName, selectStyles ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled True ] )

                        else
                            ( "Select", [ Style.classes.button.confirm, onClick <| FoodGroup.SelectFood <| complexFood ] )
                in
                [ td [ Style.classes.editable, Style.classes.numberCell ] []
                , td [ Style.classes.editable, Style.classes.numberCell ] []
                , td [ Style.classes.controls ] [ button (Style.classes.button.select :: selectStyles) [ text <| selectName ] ]
                , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexFood.recipeId ]
                , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton configuration complexFood.recipeId ]
                ]
        }
        main


amountInfoOf : ComplexFood -> String
amountInfoOf complexFood =
    String.concat
        [ complexFood.amountGrams |> String.fromFloat
        , "g"
        , Maybe.Extra.unwrap ""
            (\amountMillilitres -> String.concat [ " = ", amountMillilitres |> String.fromFloat ])
            complexFood.amountMilliLitres
        ]
