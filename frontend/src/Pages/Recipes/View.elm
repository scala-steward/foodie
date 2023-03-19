module Pages.Recipes.View exposing (editRecipeLineWith, recipeLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Page as Page
import Pages.Recipes.Pagination as Pagination
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate
import Util.DictList as DictList
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Just ViewUtil.Recipes
        , showNavigation = True
        }
        main
    <|
        let
            viewRecipeState =
                Editing.unpack
                    { onView = viewRecipeLine configuration
                    , onUpdate = always updateRecipeLine
                    , onDelete = deleteRecipeLine
                    }

            filterOn =
                SearchUtil.search main.searchString

            viewEditRecipes =
                main.recipes
                    |> DictList.filter
                        (\_ v ->
                            filterOn v.original.name
                                || filterOn (v.original.description |> Maybe.withDefault "")
                        )
                    |> DictList.values
                    |> List.sortBy (.original >> .name >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.recipes
                        }
                        main

            ( button, creationLine ) =
                createRecipe main.recipeToAdd
                    |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
                    |> Tuple.mapBoth List.concat List.concat
        in
        div [ Style.ids.addRecipeView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (tableHeader
                            ++ [ tbody []
                                    (creationLine
                                        ++ (viewEditRecipes |> Paginate.page |> List.concatMap viewRecipeState)
                                    )
                               ]
                        )
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.recipes
                                    }
                                    main
                                    >> Page.SetPagination
                            , elements = viewEditRecipes
                            }
                        ]
                   ]
            )


tableHeader : List (Html msg)
tableHeader =
    [ colgroup []
        [ col [] []
        , col [] []
        , col [] []
        , col [] []
        , col [] []
        ]
    , thead []
        [ tr [ Style.classes.tableHeader, Style.classes.recipeEditTable ]
            [ th [] [ label [] [ text "Name" ] ]
            , th [] [ label [] [ text "Description" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
            , th [ Style.classes.toggle ] []
            ]
        ]
    ]


createRecipe : Maybe RecipeCreationClientInput -> Either (List (Html Page.LogicMsg)) (List (Html Page.LogicMsg))
createRecipe maybeCreation =
    case maybeCreation of
        Nothing ->
            [ div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick <| Page.UpdateRecipeCreation <| Just <| RecipeCreationClientInput.default
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
                [ button [ Style.classes.button.edit, Page.EnterEditRecipe recipe.id |> onClick ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.ingredientEditor.address <| recipe.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Ingredients" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick (Page.RequestDeleteRecipe recipe.id) ]
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
        , toggleCommand = Page.ToggleControls recipe.id
        , showControls = showControls
        }
        recipe


deleteRecipeLine : Recipe -> List (Html Page.LogicMsg)
deleteRecipeLine recipe =
    recipeLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteRecipe recipe.id) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick (Page.CancelDeleteRecipe recipe.id) ]
                    [ text "Cancel" ]
                ]
            ]
        , toggleCommand = Page.ToggleControls recipe.id
        , showControls = True
        }
        recipe


recipeLineWith :
    { controls : List (Html msg)
    , toggleCommand : msg
    , showControls : Bool
    }
    -> Recipe
    -> List (Html msg)
recipeLineWith ps recipe =
    let
        withOnClick =
            (::) (ps.toggleCommand |> onClick)

        infoRow =
            tr [ Style.classes.editing ]
                [ td ([ Style.classes.editable ] |> withOnClick)
                    [ label [] [ text recipe.name ] ]
                , td ([ Style.classes.editable ] |> withOnClick)
                    [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
                , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick)
                    [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
                , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick)
                    [ label [] [ text <| Maybe.withDefault "" <| recipe.servingSize ] ]
                , HtmlUtil.toggleControlsCell ps.toggleCommand
                ]

        controlsRow =
            tr []
                [ td [ colspan 4 ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] ps.controls ] ]
                ]
    in
    infoRow
        :: (if ps.showControls then
                [ controlsRow ]

            else
                []
           )


updateRecipeLine : RecipeUpdateClientInput -> List (Html Page.LogicMsg)
updateRecipeLine recipeUpdateClientInput =
    editRecipeLineWith
        { saveMsg = Page.SaveRecipeEdit recipeUpdateClientInput.id
        , nameLens = RecipeUpdateClientInput.lenses.name
        , descriptionLens = RecipeUpdateClientInput.lenses.description
        , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
        , servingSizeLens = RecipeUpdateClientInput.lenses.servingSize
        , updateMsg = Page.UpdateRecipe
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditRecipeAt recipeUpdateClientInput.id
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Page.ToggleControls recipeUpdateClientInput.id |> Just
        }
        recipeUpdateClientInput


createRecipeLine : RecipeCreationClientInput -> List (Html Page.LogicMsg)
createRecipeLine =
    editRecipeLineWith
        { saveMsg = Page.CreateRecipe
        , nameLens = RecipeCreationClientInput.lenses.name
        , descriptionLens = RecipeCreationClientInput.lenses.description
        , numberOfServingsLens = RecipeCreationClientInput.lenses.numberOfServings
        , servingSizeLens = RecipeCreationClientInput.lenses.servingSize
        , updateMsg = Just >> Page.UpdateRecipeCreation
        , confirmName = "Add"
        , cancelMsg = Page.UpdateRecipeCreation Nothing
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
