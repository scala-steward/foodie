module Pages.Recipes.View exposing (editRecipeLineWith, recipeInfoColumns, recipeLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, input, label, td, text, th, tr)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Page as Page
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.ParentEditor.Page
import Pages.Util.ParentEditor.View
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain =
    Pages.Util.ParentEditor.View.viewParentsWith
        { currentPage = ViewUtil.Recipes
        , matchesSearchText =
            \string recipe ->
                SearchUtil.search string recipe.name
                    || SearchUtil.search string (recipe.description |> Maybe.withDefault "")
        , sortBy = .name
        , tableHeader = tableHeader
        , viewLine = viewRecipeLine
        , updateLine = \_ -> updateRecipeLine
        , deleteLine = deleteRecipeLine
        , create =
            { ifCreating = createRecipeLine
            , default = RecipeCreationClientInput.default
            , label = "New recipe"
            }
        , styling = Style.ids.addRecipeView
        }


tableHeader : Html msg
tableHeader =
    Pages.Util.ParentEditor.View.tableHeaderWith
        { columns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [] [ label [] [ text "Description" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
            ]
        , style = Style.classes.recipeEditTable
        }


viewRecipeLine : Configuration -> Recipe -> Bool -> List (Html Page.LogicMsg)
viewRecipeLine configuration recipe showControls =
    recipeLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.edit, Pages.Util.ParentEditor.Page.EnterEdit recipe.id |> onClick ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.ingredientEditor.address <| recipe.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Ingredients" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick (Pages.Util.ParentEditor.Page.RequestDelete recipe.id) ]
                    [ text "Delete" ]
                ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsRecipeSelect.address <| recipe.id
                    , attributes = [ Style.classes.button.nutrients ]
                    , children = [ text "Nutrients" ]
                    }
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls recipe.id
        , showControls = showControls
        }
        recipe


deleteRecipeLine : Recipe -> List (Html Page.LogicMsg)
deleteRecipeLine recipe =
    recipeLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.ConfirmDelete <| recipe.id ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.CancelDelete <| recipe.id ]
                    [ text "Cancel" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls recipe.id
        , showControls = True
        }
        recipe


recipeInfoColumns : Recipe -> List (HtmlUtil.Column msg)
recipeInfoColumns recipe =
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


recipeLineWith :
    { controls : List (Html msg)
    , toggleMsg : msg
    , showControls : Bool
    }
    -> Recipe
    -> List (Html msg)
recipeLineWith ps =
    Pages.Util.ParentEditor.View.lineWith
        { rowWithControls =
            \recipe ->
                { display = recipeInfoColumns recipe
                , controls = ps.controls
                }
        , toggleMsg = ps.toggleMsg
        , showControls = ps.showControls
        }


updateRecipeLine : RecipeUpdateClientInput -> List (Html Page.LogicMsg)
updateRecipeLine recipeUpdateClientInput =
    editRecipeLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.SaveEdit recipeUpdateClientInput.id
        , nameLens = RecipeUpdateClientInput.lenses.name
        , descriptionLens = RecipeUpdateClientInput.lenses.description
        , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
        , servingSizeLens = RecipeUpdateClientInput.lenses.servingSize
        , updateMsg = Pages.Util.ParentEditor.Page.Edit
        , confirmName = "Save"
        , cancelMsg = Pages.Util.ParentEditor.Page.ExitEdit recipeUpdateClientInput.id
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls recipeUpdateClientInput.id |> Just
        }
        recipeUpdateClientInput


createRecipeLine : RecipeCreationClientInput -> List (Html Page.LogicMsg)
createRecipeLine =
    editRecipeLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.Create
        , nameLens = RecipeCreationClientInput.lenses.name
        , descriptionLens = RecipeCreationClientInput.lenses.description
        , numberOfServingsLens = RecipeCreationClientInput.lenses.numberOfServings
        , servingSizeLens = RecipeCreationClientInput.lenses.servingSize
        , updateMsg = Just >> Pages.Util.ParentEditor.Page.UpdateCreation
        , confirmName = "Add"
        , cancelMsg = Pages.Util.ParentEditor.Page.UpdateCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Nothing
        }


editRecipeLineWith :
    { saveMsg : msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , descriptionLens : Lens editedValue (Maybe String)
    , numberOfServingsLens : Lens editedValue (ValidatedInput Float)
    , servingSizeLens : Lens editedValue (Maybe String)
    , updateMsg : editedValue -> msg
    , confirmName : String
    , cancelMsg : msg
    , cancelName : String
    , rowStyles : List (Attribute msg)
    , toggleCommand : Maybe msg
    }
    -> editedValue
    -> List (Html msg)
editRecipeLineWith handling editedValue =
    let
        validInput =
            List.all identity
                [ handling.nameLens.get editedValue |> ValidatedInput.isValid
                , handling.numberOfServingsLens.get editedValue |> ValidatedInput.isValid
                ]

        validatedSaveAction =
            MaybeUtil.optional validInput <| onEnter handling.saveMsg

        infoColumns =
            [ td [ Style.classes.editable ]
                [ input
                    ([ MaybeUtil.defined <| value <| .text <| handling.nameLens.get <| editedValue
                     , MaybeUtil.defined <|
                        onInput <|
                            flip (ValidatedInput.lift handling.nameLens).set editedValue
                                >> handling.updateMsg
                     , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                     , validatedSaveAction
                     ]
                        |> Maybe.Extra.values
                    )
                    []
                ]
            , td [ Style.classes.editable ]
                [ input
                    ([ MaybeUtil.defined <| value <| Maybe.withDefault "" <| handling.descriptionLens.get <| editedValue
                     , MaybeUtil.defined <|
                        onInput <|
                            flip
                                (Just
                                    >> Maybe.Extra.filter (String.isEmpty >> not)
                                    >> handling.descriptionLens.set
                                )
                                editedValue
                                >> handling.updateMsg
                     , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                     , validatedSaveAction
                     ]
                        |> Maybe.Extra.values
                    )
                    []
                ]
            , td [ Style.classes.numberCell ]
                [ input
                    ([ MaybeUtil.defined <| value <| .text <| handling.numberOfServingsLens.get <| editedValue
                     , MaybeUtil.defined <|
                        onInput <|
                            flip
                                (ValidatedInput.lift
                                    handling.numberOfServingsLens
                                ).set
                                editedValue
                                >> handling.updateMsg
                     , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                     , MaybeUtil.defined <| Style.classes.numberLabel
                     , validatedSaveAction
                     ]
                        |> Maybe.Extra.values
                    )
                    []
                ]
            , td [ Style.classes.numberCell ]
                [ input
                    ([ MaybeUtil.defined <| value <| Maybe.withDefault "" <| handling.servingSizeLens.get <| editedValue
                     , MaybeUtil.defined <|
                        onInput <|
                            flip
                                (Just
                                    >> Maybe.Extra.filter (String.isEmpty >> not)
                                    >> handling.servingSizeLens.set
                                )
                                editedValue
                                >> handling.updateMsg
                     , MaybeUtil.defined <| Style.classes.numberLabel
                     , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                     , validatedSaveAction
                     ]
                        |> Maybe.Extra.values
                    )
                    []
                ]
            ]

        controlsRow =
            Pages.Util.ParentEditor.View.controlsRowWith
                { colspan = infoColumns |> List.length
                , validInput = validInput
                , confirm =
                    { msg = handling.saveMsg
                    , name = handling.confirmName
                    }
                , cancel =
                    { msg = handling.cancelMsg
                    , name = handling.cancelName
                    }
                }

        commandToggle =
            handling.toggleCommand
                |> Maybe.Extra.toList
                |> List.map HtmlUtil.toggleControlsCell
    in
    [ tr handling.rowStyles (infoColumns ++ commandToggle)
    , controlsRow
    ]
