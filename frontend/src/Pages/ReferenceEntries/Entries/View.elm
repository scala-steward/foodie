module Pages.ReferenceEntries.Entries.View exposing (..)

import Api.Types.NutrientUnit as NutrientUnit
import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ReferenceEntries.Entries.Page as Page
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewReferenceEntries : Page.Main -> Html Page.LogicMsg
viewReferenceEntries main =
    Pages.Util.Choice.View.viewElements
        { nameOfChoice = .name
        , choiceIdOfElement = .nutrientCode
        , idOfElement = .nutrientCode
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Reference value" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
            ]
        , info =
            \referenceEntry ->
                let
                    nutrient =
                        DictList.get referenceEntry.nutrientCode main.choices |> Maybe.map .original
                in
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| nutrient ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children = [ label [] [ text <| String.fromFloat <| referenceEntry.amount ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children =
                            [ label [ Style.classes.numberLabel ] [ text <| Maybe.Extra.unwrap "" (.unit >> NutrientUnit.toString) <| nutrient ] ]
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick <| Pages.Util.Choice.Page.EnterEdit <| referenceEntry.nutrientCode ] [ text "Edit" ] ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| Pages.Util.Choice.Page.RequestDelete <| referenceEntry.nutrientCode ] [ text "Delete" ] ]
                    ]
                }
        , isValidInput = .amount >> ValidatedInput.isValid
        , edit =
            \referenceEntry referenceEntryUpdateClientInput ->
                let
                    nutrient =
                        DictList.get referenceEntry.nutrientCode main.choices |> Maybe.map .original
                in
                [ { attributes = []
                  , children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| nutrient ] ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value
                                referenceEntryUpdateClientInput.amount.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ReferenceEntryUpdateClientInput.lenses.amount
                                    ).set
                                    referenceEntryUpdateClientInput
                                    >> Pages.Util.Choice.Page.Edit
                                )
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ label [ Style.classes.numberLabel ]
                            [ text <| Maybe.Extra.unwrap "" (.unit >> NutrientUnit.toString) <| nutrient
                            ]
                        ]
                  }
                ]
        }
        main


viewNutrients : Page.Main -> Html Page.LogicMsg
viewNutrients main =
    let
        ( referenceValue, unit ) =
            if DictListUtil.existsValue Editing.isUpdate main.choices then
                ( "Reference value", "Unit" )

            else
                ( "", "" )
    in
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string -> .name >> SearchUtil.search string
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text referenceValue ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text unit ] ]
            ]
        , idOfChoice = .code
        , nameOfChoice = .name
        , elementCreationLine =
            \nutrient creation ->
                let
                    validInput =
                        creation.amount |> ValidatedInput.isValid

                    addMsg =
                        Pages.Util.Choice.Page.Create nutrient.code

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice nutrient.code
                in
                { display =
                    [ { attributes = [ Style.classes.numberCell ]
                      , children =
                            [ input
                                ([ MaybeUtil.defined <| value creation.amount.text
                                 , MaybeUtil.defined <|
                                    onInput
                                        (flip
                                            (ValidatedInput.lift
                                                ReferenceEntryCreationClientInput.lenses.amount
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
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel, onClick <| Pages.Util.Choice.Page.SelectChoice <| nutrient ]
                      , children = [ label [] [ text <| NutrientUnit.toString <| .unit <| nutrient ] ]
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
            \nutrient ->
                let
                    exists =
                        DictListUtil.existsValue (\n -> n.original.nutrientCode == nutrient.code) main.elements

                    ( selectName, selectStyles ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled True ] )

                        else
                            ( "Select", [ Style.classes.button.confirm, onClick <| Pages.Util.Choice.Page.SelectChoice <| nutrient ] )
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
                    ]
                }
        }
        main
