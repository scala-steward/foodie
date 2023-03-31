module Pages.Recipes.View exposing (editRecipeLineWith, recipeInfoLineWith, recipeLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Html exposing (Attribute, Html, button, div, input, label, table, td, text, th, tr)
import Html.Attributes exposing (colspan, disabled, value)
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
        , create = createRecipe
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
        }


createRecipe : Maybe RecipeCreationClientInput -> Either (List (Html Page.LogicMsg)) (List (Html Page.LogicMsg))
createRecipe maybeCreation =
    case maybeCreation of
        Nothing ->
            [ div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick <| Pages.Util.ParentEditor.Page.UpdateCreation <| Just <| RecipeCreationClientInput.default
                    ]
                    [ text "New recipe" ]
                ]
            ]
                |> Left

        Just creation ->
            createRecipeLine creation |> Right


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
        , extraCells = []
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls recipe.id
        , showControls = showControls
        }
        recipe


deleteRecipeLine : Recipe -> List (Html Page.LogicMsg)
deleteRecipeLine recipe =
    recipeLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick (Pages.Util.ParentEditor.Page.ConfirmDelete recipe.id) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick (Pages.Util.ParentEditor.Page.CancelDelete recipe.id) ]
                    [ text "Cancel" ]
                ]
            ]
        , extraCells = []
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls recipe.id
        , showControls = True
        }
        recipe


recipeInfoLineWith :
    { toggleCommand : msg
    , extraCells : List (Html msg)
    }
    -> Recipe
    -> Html msg
recipeInfoLineWith ps recipe =
    let
        withOnClick =
            (::) (ps.toggleCommand |> onClick)
    in
    tr [ Style.classes.editing ]
        ([ td ([ Style.classes.editable ] |> withOnClick)
            [ label [] [ text recipe.name ] ]
         , td ([ Style.classes.editable ] |> withOnClick)
            [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick)
            [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick)
            [ label [] [ text <| Maybe.withDefault "" <| recipe.servingSize ] ]
         ]
            ++ ps.extraCells
            ++ [ HtmlUtil.toggleControlsCell ps.toggleCommand
               ]
        )


recipeLineWith :
    { controls : List (Html msg)
    , extraCells : List (Html msg)
    , toggleCommand : msg
    , showControls : Bool
    }
    -> Recipe
    -> List (Html msg)
recipeLineWith ps recipe =
    recipeInfoLineWith
        { toggleCommand = ps.toggleCommand
        , extraCells = ps.extraCells
        }
        recipe
        :: (if ps.showControls then
                [ tr []
                    [ td [ colspan (4 + (ps.extraCells |> List.length)) ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] ps.controls ] ]
                    ]
                ]

            else
                []
           )


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

        controlsRow =
            tr []
                [ td [ colspan 4 ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr []
                            [ td [ Style.classes.controls ]
                                [ button
                                    ([ MaybeUtil.defined <| Style.classes.button.confirm
                                     , MaybeUtil.defined <| disabled <| not <| validInput
                                     , MaybeUtil.optional validInput <| onClick handling.saveMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    [ text handling.confirmName ]
                                ]
                            , td [ Style.classes.controls ]
                                [ button [ Style.classes.button.cancel, onClick handling.cancelMsg ]
                                    [ text handling.cancelName ]
                                ]
                            ]
                        ]
                    ]
                ]

        commandToggle =
            handling.toggleCommand
                |> Maybe.Extra.unwrap []
                    (HtmlUtil.toggleControlsCell >> List.singleton)
    in
    [ tr handling.rowStyles
        ([ td [ Style.classes.editable ]
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
            ++ commandToggle
        )
    , controlsRow
    ]
