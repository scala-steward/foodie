module Pages.ComplexFoods.View exposing (..)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, div, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewComplexFoods : Configuration -> Page.Main -> Html Page.LogicMsg
viewComplexFoods configuration main =
    Pages.Util.Choice.View.viewMain
        { nameOfChoice = .name
        , choiceIdOfElement = .recipeId
        , idOfElement = .recipeId
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount in g" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount in ml" ] ]
            ]
        , info =
            \complexFood ->
                [ { attributes = [ Style.classes.editable ]
                  , children = [ label [] [ text <| .name <| complexFood ] ]
                  }
                , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                  , children = [ label [] [ text <| String.fromFloat <| complexFood.amountGrams ] ]
                  }
                , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                  , children = [ label [] [ text <| Maybe.Extra.unwrap "" String.fromFloat <| complexFood.amountMilliLitres ] ]
                  }
                ]
        , controls =
            \complexFood ->
                [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick <| Pages.Util.Choice.Page.EnterEdit <| complexFood.recipeId ] [ text "Edit" ] ]
                , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| Pages.Util.Choice.Page.RequestDelete <| complexFood.recipeId ] [ text "Delete" ] ]
                , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration complexFood.recipeId ]
                , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton configuration complexFood.recipeId ]
                ]
        , isValidInput =
            \complexFoodClientInput ->
                List.all identity
                    [ complexFoodClientInput.amountGrams |> ValidatedInput.isValid
                    , complexFoodClientInput.amountMilliLitres |> ValidatedInput.isValid
                    ]
        , edit =
            \complexFood complexFoodClientInput ->
                [ { attributes = []
                  , children = [ label [] [ text <| .name <| complexFood ] ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value <| complexFoodClientInput.amountGrams.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexFoodClientInput.lenses.amountGrams
                                    ).set
                                    complexFoodClientInput
                                    >> Pages.Util.Choice.Page.Edit
                                )
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value <| complexFoodClientInput.amountMilliLitres.text
                            , onInput <|
                                flip
                                    (ValidatedInput.lift
                                        ComplexFoodClientInput.lenses.amountMilliLitres
                                    ).set
                                    complexFoodClientInput
                                    >> Pages.Util.Choice.Page.Edit
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                ]
        }
        main


viewRecipes : Configuration -> Page.Main -> Html Page.LogicMsg
viewRecipes configuration main =
    let
        anySelection =
            main.choices
                |> DictListUtil.existsValue Editing.isUpdate

        ( amountGrams, amountMillilitres ) =
            if anySelection then
                ( "Amount in g", "Amount in ml" )

            else
                ( "", "" )
    in
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string recipe -> SearchUtil.search string recipe.name || SearchUtil.search string (recipe.description |> Maybe.withDefault "")
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [] [ label [] [ text "Description" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Number of servings" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amountGrams ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amountMillilitres ] ]
            ]
        , idOfChoice = .id
        , nameOfChoice = .name
        , elementCreationLine =
            \recipe complexFoodClientInput ->
                let
                    createMsg =
                        Pages.Util.Choice.Page.Create recipe.id

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice recipe.id

                    validInput =
                        List.all identity
                            [ complexFoodClientInput.amountGrams |> ValidatedInput.isValid
                            , complexFoodClientInput.amountMilliLitres |> ValidatedInput.isValid
                            ]

                    inputCells =
                        [ { attributes = [ Style.classes.numberCell ]
                          , children =
                                [ input
                                    ([ MaybeUtil.defined <| value complexFoodClientInput.amountGrams.text
                                     , MaybeUtil.defined <|
                                        onInput <|
                                            flip
                                                (ValidatedInput.lift
                                                    ComplexFoodClientInput.lenses.amountGrams
                                                ).set
                                                complexFoodClientInput
                                                >> Pages.Util.Choice.Page.UpdateCreation
                                     , MaybeUtil.defined <| Style.classes.numberLabel
                                     , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                                     , MaybeUtil.optional validInput <| onEnter createMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    []
                                ]
                          }
                        , { attributes = [ Style.classes.numberCell ]
                          , children =
                                [ input
                                    ([ MaybeUtil.defined <| value complexFoodClientInput.amountMilliLitres.text
                                     , MaybeUtil.defined <|
                                        onInput <|
                                            flip
                                                (ValidatedInput.lift
                                                    ComplexFoodClientInput.lenses.amountMilliLitres
                                                ).set
                                                complexFoodClientInput
                                                >> Pages.Util.Choice.Page.UpdateCreation
                                     , MaybeUtil.defined <| Style.classes.numberLabel
                                     , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                                     , MaybeUtil.optional validInput <| onEnter createMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    []
                                ]
                          }
                        ]
                in
                { display = displayRecipe recipe ++ inputCells
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| Style.classes.button.confirm
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick createMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text <| "Add"
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick cancelMsg ] [ text "Cancel" ] ]
                    ]
                }
        , viewChoiceLine =
            \recipe ->
                let
                    exists =
                        DictListUtil.existsValue (\complexFood -> complexFood.original.recipeId == recipe.id) main.elements

                    ( buttonText, buttonAttributes ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled <| True ] )

                        else
                            ( "Select", [ Style.classes.button.select, onClick <| Pages.Util.Choice.Page.SelectChoice <| recipe ] )
                in
                { display = displayRecipe recipe
                , controls =
                    [ td [ Style.classes.controls ] [ button buttonAttributes [ text <| buttonText ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton configuration recipe.id ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton configuration recipe.id ]
                    ]
                }
        }
        main


displayRecipe : Recipe -> List (Pages.Util.Choice.View.Column msg)
displayRecipe recipe =
    [ { attributes = [ Style.classes.editable ]
      , children = [ label [] [ text recipe.name ] ]
      }
    , { attributes = [ Style.classes.editable ]
      , children = [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
      }
    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
      , children = [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
      }
    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
      , children = [ label [] [ text <| Maybe.withDefault "" <| recipe.servingSize ] ]
      }
    ]


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Just ViewUtil.ComplexFoods
        , showNavigation = True
        }
        main
    <|
        div [ Style.ids.complexFoodEditor ]
            [ div [ Style.classes.elements ] [ label [] [ text "Complex foods" ] ]
            , viewMain configuration main
            , div [ Style.classes.elements ] [ label [] [ text "Recipes" ] ]
            , viewRecipes configuration main
            ]
