module Pages.Ingredients.Recipe.View exposing (viewMain)

import Addresses.Frontend
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, table, tbody, td, text)
import Html.Events exposing (onClick)
import Pages.Ingredients.Recipe.Page as Page
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput
import Pages.Recipes.View
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Util.Editing as Editing


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    let
        viewRecipe =
            Editing.unpack
                { onView =
                    \recipe showControls ->
                        Pages.Recipes.View.recipeLineWith
                            { controls =
                                [ td [ Style.classes.controls ]
                                    [ button [ Style.classes.button.edit, Page.EnterEdit |> onClick ] [ text "Edit" ] ]
                                , td [ Style.classes.controls ]
                                    [ button
                                        [ Style.classes.button.delete, Page.RequestDelete |> onClick ]
                                        [ text "Delete" ]
                                    ]
                                , td [ Style.classes.controls ]
                                    [ Links.linkButton
                                        { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsRecipeSelect.address <| main.recipe.original.id
                                        , attributes = [ Style.classes.button.nutrients ]
                                        , children = [ text "Nutrients" ]
                                        }
                                    ]
                                ]
                            , extraCells = []
                            , toggleCommand = Page.ToggleControls
                            , showControls = showControls
                            }
                            recipe
                , onUpdate =
                    Pages.Recipes.View.editRecipeLineWith
                        { saveMsg = Page.SaveEdit
                        , nameLens = RecipeUpdateClientInput.lenses.name
                        , descriptionLens = RecipeUpdateClientInput.lenses.description
                        , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
                        , servingSizeLens = RecipeUpdateClientInput.lenses.servingSize
                        , updateMsg = Page.Edit
                        , confirmName = "Save"
                        , cancelMsg = Page.ExitEdit
                        , cancelName = "Cancel"
                        , rowStyles = []
                        , toggleCommand = Just Page.ToggleControls
                        }
                        |> always
                , onDelete =
                    Pages.Recipes.View.recipeLineWith
                        { controls =
                            [ td [ Style.classes.controls ]
                                [ button [ Style.classes.button.delete, onClick <| Page.ConfirmDelete ] [ text "Delete?" ] ]
                            , td [ Style.classes.controls ]
                                [ button
                                    [ Style.classes.button.confirm, onClick <| Page.CancelDelete ]
                                    [ text "Cancel" ]
                                ]
                            ]
                        , toggleCommand = Page.ToggleControls
                        , extraCells = []
                        , showControls = True
                        }
                }
                main.recipe
    in
    table [ Style.classes.elementsWithControlsTable ]
        (Pages.Recipes.View.tableHeader
            ++ [ tbody [] viewRecipe
               ]
        )
