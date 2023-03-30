module Pages.MealEntries.Meal.View exposing (..)

import Addresses.Frontend
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, td, text)
import Html.Events exposing (onClick)
import Pages.MealEntries.Meal.Page as Page
import Pages.Meals.MealUpdateClientInput as MealUpdateClientInput
import Pages.Meals.View
import Pages.Util.Links as Links
import Pages.Util.Parent.Page
import Pages.Util.Parent.View
import Pages.Util.Style as Style


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    Pages.Util.Parent.View.viewMain
        { tableHeader = Pages.Meals.View.tableHeader
        , onView =
            \meal showControls ->
                Pages.Meals.View.mealLineWith
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
                                { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsMealSelect.address <| main.parent.original.id
                                , attributes = [ Style.classes.button.nutrients ]
                                , children = [ text "Nutrients" ]
                                }
                            ]
                        ]
                    , toggleCommand = Pages.Util.Parent.Page.ToggleControls
                    , showControls = showControls
                    }
                    meal
        , onUpdate =
            Pages.Meals.View.editMealLineWith
                { saveMsg = Pages.Util.Parent.Page.SaveEdit
                , dateLens = MealUpdateClientInput.lenses.date
                , setDate = True
                , nameLens = MealUpdateClientInput.lenses.name
                , updateMsg = Pages.Util.Parent.Page.Edit
                , confirmName = "Save"
                , cancelMsg = Pages.Util.Parent.Page.ExitEdit
                , cancelName = "Cancel"
                , rowStyles = []
                , toggleCommand = Just Pages.Util.Parent.Page.ToggleControls
                }
                |> always
        , onDelete =
            Pages.Meals.View.mealLineWith
                { controls =
                    [ td [ Style.classes.controls ]
                        [ button [ Style.classes.button.delete, onClick <| Pages.Util.Parent.Page.ConfirmDelete ] [ text "Delete?" ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm, onClick <| Pages.Util.Parent.Page.CancelDelete ]
                            [ text "Cancel" ]
                        ]
                    ]
                , toggleCommand = Pages.Util.Parent.Page.ToggleControls
                , showControls = True
                }
        }
        main
