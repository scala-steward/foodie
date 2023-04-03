module Pages.Ingredients.Recipe.View exposing (viewMain)

import Addresses.Frontend
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, td, text)
import Html.Events exposing (onClick)
import Pages.Ingredients.Recipe.Page as Page
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput
import Pages.Recipes.View
import Pages.Util.Links as Links
import Pages.Util.Parent.Page
import Pages.Util.Parent.View
import Pages.Util.Style as Style


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    Pages.Util.Parent.View.viewMain
        { tableHeader = Pages.Recipes.View.tableHeader
        , onView =
            \recipe showControls ->
                Pages.Recipes.View.recipeLineWith
                    { controls =
                        [ td [ Style.classes.controls ]
                            [ button [ Style.classes.button.edit, Pages.Util.Parent.Page.EnterEdit |> onClick ] [ text "Edit" ] ]
                        , td [ Style.classes.controls ]
                            [ button
                                [ Style.classes.button.delete, Pages.Util.Parent.Page.RequestDelete |> onClick ]
                                [ text "Delete" ]
                            ]
                        , td [ Style.classes.controls ]
                            [ Links.linkButton
                                { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsRecipeSelect.address <| main.parent.original.id
                                , attributes = [ Style.classes.button.nutrients ]
                                , children = [ text "Nutrients" ]
                                }
                            ]
                        ]
                    , toggleMsg = Pages.Util.Parent.Page.ToggleControls
                    , showControls = showControls
                    }
                    recipe
        , onUpdate =
            Pages.Recipes.View.editRecipeLineWith
                { saveMsg = Pages.Util.Parent.Page.SaveEdit
                , nameLens = RecipeUpdateClientInput.lenses.name
                , descriptionLens = RecipeUpdateClientInput.lenses.description
                , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
                , servingSizeLens = RecipeUpdateClientInput.lenses.servingSize
                , updateMsg = Pages.Util.Parent.Page.Edit
                , confirmName = "Save"
                , cancelMsg = Pages.Util.Parent.Page.ExitEdit
                , cancelName = "Cancel"
                , rowStyles = []
                , toggleCommand = Just Pages.Util.Parent.Page.ToggleControls
                }
                |> always
        , onDelete =
            Pages.Recipes.View.recipeLineWith
                { controls =
                    [ td [ Style.classes.controls ]
                        [ button [ Style.classes.button.delete, onClick <| Pages.Util.Parent.Page.ConfirmDelete ] [ text "Delete?" ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm, onClick <| Pages.Util.Parent.Page.CancelDelete ]
                            [ text "Cancel" ]
                        ]
                    ]
                , toggleMsg = Pages.Util.Parent.Page.ToggleControls
                , showControls = True
                }
        }
        main
