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
import Pages.Util.Choice.ChoiceGroup as ChoiceGroup
import Pages.Util.Choice.ChoiceGroupView as ChoiceGroupView
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ChoiceGroupView.viewMain
        { nameOfChoice = .name
        , choiceIdOfElement = .complexFoodId
        , idOfElement = .complexFoodId
        , info =
            \complexIngredient ->
                let
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.choices |> Maybe.map .original

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
                        ChoiceGroup.EnterEdit complexIngredient.complexFoodId |> onClick
                in
                [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
                , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (ChoiceGroup.RequestDelete complexIngredient.complexFoodId) ] [ text "Delete" ] ]
                , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexIngredient.complexFoodId ]
                ]
        , isValidInput = .factor >> ValidatedInput.isValid
        , edit =
            \complexIngredient complexIngredientUpdateClientInput ->
                let
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.choices |> Maybe.map .original
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
                                    >> ChoiceGroup.Edit
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


viewFoods : Configuration -> Page.Main -> Html Page.LogicMsg
viewFoods configuration main =
    let
        ( factor, amount ) =
            if DictListUtil.existsValue Editing.isUpdate main.choices then
                ( "Factor", "Amount" )

            else
                ( "", "" )
    in
    ChoiceGroupView.viewChoices
        { matchesSearchText = \string -> .name >> SearchUtil.search string
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text factor ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amount ] ]
            ]
        , idOfChoice = .recipeId
        , nameOfChoice = .name
        , elementCreationLine =
            \complexFood creation ->
                [ td [ Style.classes.numberCell ]
                    [ input
                        [ value creation.factor.text
                        , onInput
                            (flip
                                (ValidatedInput.lift
                                    ComplexIngredientClientInput.lenses.factor
                                ).set
                                creation
                                >> ChoiceGroup.UpdateCreation
                            )
                        , Style.classes.numberLabel
                        ]
                        []
                    ]
                , td [ Style.classes.editable, Style.classes.numberLabel, onClick <| ChoiceGroup.SelectChoice <| complexFood ]
                    [ label [] [ text <| amountInfoOf <| complexFood ] ]
                ]
        , elementCreationControls =
            \food creation ->
                let
                    validInput =
                        creation.factor |> ValidatedInput.isValid
                in
                [ td [ Style.classes.controls ]
                    [ button
                        ([ MaybeUtil.defined <| Style.classes.button.confirm
                         , MaybeUtil.defined <| disabled <| not <| validInput
                         , MaybeUtil.optional validInput <| onClick <| ChoiceGroup.Create <| food.recipeId
                         ]
                            |> Maybe.Extra.values
                        )
                        [ text "Add"
                        ]
                    ]
                , td [ Style.classes.controls ]
                    [ button [ Style.classes.button.cancel, onClick <| ChoiceGroup.DeselectChoice <| food.recipeId ]
                        [ text "Cancel" ]
                    ]
                ]
        , viewChoiceLine =
            \_ ->
                [ { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                  , children = []
                  }
                , { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                  , children = []
                  }
                ]
        , viewChoiceLineControls =
            \complexFood ->
                let
                    exists =
                        DictListUtil.existsValue (\complexIngredient -> complexIngredient.original.complexFoodId == complexFood.recipeId) main.elements

                    ( selectName, selectStyles ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled True ] )

                        else
                            ( "Select", [ Style.classes.button.confirm, onClick <| ChoiceGroup.SelectChoice <| complexFood ] )
                in
                [ td [ Style.classes.controls ] [ button selectStyles [ text <| selectName ] ]
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
