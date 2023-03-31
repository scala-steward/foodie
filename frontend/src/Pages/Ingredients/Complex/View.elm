module Pages.Ingredients.Complex.View exposing (viewComplexIngredients, viewFoods)

import Api.Types.ComplexFood exposing (ComplexFood)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Pages.Ingredients.Complex.Page as Page
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewComplexIngredients : Configuration -> Page.Main -> Html Page.LogicMsg
viewComplexIngredients configuration main =
    Pages.Util.Choice.View.viewElements
        { nameOfChoice = .name
        , choiceIdOfElement = .complexFoodId
        , idOfElement = .complexFoodId
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Factor" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
            ]
        , info =
            \complexIngredient ->
                let
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.choices |> Maybe.map .original

                    amountInfo =
                        complexFood
                            |> Maybe.Extra.unwrap "" amountInfoOf

                    editMsg =
                        Pages.Util.Choice.Page.EnterEdit complexIngredient.complexFoodId |> onClick
                in
                { display =
                    [ { attributes = [ Style.classes.editable ], children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ] }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ], children = [ label [] [ text <| String.fromFloat <| complexIngredient.factor ] ] }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ], children = [ label [] [ text <| amountInfo ] ] }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Pages.Util.Choice.Page.RequestDelete complexIngredient.complexFoodId) ] [ text "Delete" ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexIngredient.complexFoodId ]
                    , td [ Style.classes.controls ] [ NavigationUtil.complexFoodNutrientLinkButton configuration complexIngredient.complexFoodId ]
                    ]
                }
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
                                    >> Pages.Util.Choice.Page.Edit
                                )
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                  , children =
                        [ label [] [ text <| Maybe.Extra.unwrap "" amountInfoOf <| complexFood ]
                        ]
                  }
                ]
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
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string -> .name >> SearchUtil.search string
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text factor ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amount ] ]
            ]
        , idOfChoice = .recipeId
        , elementCreationLine =
            \complexFood creation ->
                let
                    validInput =
                        creation.factor |> ValidatedInput.isValid

                    addMsg =
                        Pages.Util.Choice.Page.Create complexFood.recipeId

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice complexFood.recipeId
                in
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| .name <| complexFood ] ]
                      }
                    , { attributes = [ Style.classes.numberCell ]
                      , children =
                            [ input
                                ([ MaybeUtil.defined <| value creation.factor.text
                                 , MaybeUtil.defined <|
                                    onInput
                                        (flip
                                            (ValidatedInput.lift
                                                ComplexIngredientClientInput.lenses.factor
                                            ).set
                                            creation
                                            >> Pages.Util.Choice.Page.UpdateCreation
                                        )
                                 , MaybeUtil.defined <| Style.classes.numberLabel
                                 , MaybeUtil.defined <| HtmlUtil.onEscape <| cancelMsg
                                 , MaybeUtil.optional validInput <| onEnter <| addMsg
                                 ]
                                    |> Maybe.Extra.values
                                )
                                []
                            ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel, onClick <| Pages.Util.Choice.Page.SelectChoice <| complexFood ]
                      , children = [ label [] [ text <| amountInfoOf <| complexFood ] ]
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| Style.classes.button.confirm
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick <| addMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text "Add"
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick <| cancelMsg ]
                            [ text "Cancel" ]
                        ]
                    ]
                }
        , viewChoiceLine =
            \complexFood ->
                let
                    exists =
                        DictListUtil.existsValue (\complexIngredient -> complexIngredient.original.complexFoodId == complexFood.recipeId) main.elements

                    ( selectName, selectStyles ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled True ] )

                        else
                            ( "Select", [ Style.classes.button.confirm, onClick <| Pages.Util.Choice.Page.SelectChoice <| complexFood ] )
                in
                { display =
                    [ { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                      , children = []
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                      , children = []
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button selectStyles [ text <| selectName ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexFood.recipeId ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton configuration complexFood.recipeId ]
                    ]
                }
        }
        main


amountInfoOf : ComplexFood -> String
amountInfoOf complexFood =
    String.concat
        [ complexFood.amountGrams |> String.fromFloat
        , "g"
        , Maybe.Extra.unwrap ""
            (\amountMillilitres -> String.concat [ " = ", amountMillilitres |> String.fromFloat, "ml" ])
            complexFood.amountMilliLitres
        ]
