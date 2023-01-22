module Pages.Recipes.View exposing (editRecipeLineWith, recipeLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Page as Page
import Pages.Recipes.Pagination as Pagination
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Status as Status
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = Page.lenses.initialization.get
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just ViewUtil.Recipes
        , showNavigation = True
        }
        model
    <|
        let
            viewRecipeState =
                Editing.unpack
                    { onView = viewRecipeLine model.authorizedAccess.configuration
                    , onUpdate = always updateRecipeLine
                    , onDelete = deleteRecipeLine
                    }

            filterOn =
                SearchUtil.search model.searchString

            viewEditRecipes =
                model.recipes
                    |> Dict.filter
                        (\_ v ->
                            filterOn v.original.name
                                || filterOn (v.original.description |> Maybe.withDefault "")
                        )
                    |> Dict.values
                    |> List.sortBy (.original >> .name >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.recipes
                        }
                        model

            ( button, creationLine ) =
                createRecipe model.recipeToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ Style.ids.addRecipeView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = model.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (tableHeader { controlButtons = 4 }
                            ++ [ tbody []
                                    (creationLine
                                        ++ (viewEditRecipes |> Paginate.page |> List.map viewRecipeState)
                                    )
                               ]
                        )
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.recipes
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewEditRecipes
                            }
                        ]
                   ]
            )


tableHeader : { controlButtons : Int } -> List (Html msg)
tableHeader ps =
    [ colgroup []
        [ col [] []
        , col [] []
        , col [] []
        , col [ stringProperty "span" (ps.controlButtons |> String.fromInt) ] []
        ]
    , thead []
        [ tr [ Style.classes.tableHeader ]
            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
            , th [ scope "col" ] [ label [] [ text "Description" ] ]
            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
            , th [ colspan ps.controlButtons, scope "colgroup", Style.classes.controlsGroup ] []
            ]
        ]
    ]


createRecipe : Maybe RecipeCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createRecipe maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick <| Page.UpdateRecipeCreation <| Just <| RecipeCreationClientInput.default
                    ]
                    [ text "New recipe" ]
                ]
                |> Left

        Just creation ->
            createRecipeLine creation |> Right


viewRecipeLine : Configuration -> Recipe -> Html Page.Msg
viewRecipeLine configuration recipe =
    let
        editMsg =
            Page.EnterEditRecipe recipe.id |> onClick
    in
    recipeLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick (Page.RequestDeleteRecipe recipe.id) ]
                    [ text "Delete" ]
                ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.ingredientEditor.address <| recipe.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Ingredients" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsRecipeSelect.address <| recipe.id
                    , attributes = [ Style.classes.button.nutrients ]
                    , children = [ text "Nutrients" ]
                    }
                ]
            ]
        , onClick = [ editMsg ]
        , styles = [ Style.classes.editing ]
        }
        recipe


deleteRecipeLine : Recipe -> Html Page.Msg
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
        , onClick = []
        , styles = [ Style.classes.editing ]
        }
        recipe


recipeLineWith :
    { controls : List (Html msg)
    , onClick : List (Attribute msg)
    , styles : List (Attribute msg)
    }
    -> Recipe
    -> Html msg
recipeLineWith ps recipe =
    let
        withOnClick =
            (++) ps.onClick
    in
    tr ps.styles
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text recipe.name ] ]
         , td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
         ]
            ++ ps.controls
        )


updateRecipeLine : RecipeUpdateClientInput -> Html Page.Msg
updateRecipeLine recipeUpdateClientInput =
    editRecipeLineWith
        { saveMsg = Page.SaveRecipeEdit recipeUpdateClientInput.id
        , nameLens = RecipeUpdateClientInput.lenses.name
        , descriptionLens = RecipeUpdateClientInput.lenses.description
        , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
        , updateMsg = Page.UpdateRecipe
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditRecipeAt recipeUpdateClientInput.id
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        }
        recipeUpdateClientInput


createRecipeLine : RecipeCreationClientInput -> Html Page.Msg
createRecipeLine =
    editRecipeLineWith
        { saveMsg = Page.CreateRecipe
        , nameLens = RecipeCreationClientInput.lenses.name
        , descriptionLens = RecipeCreationClientInput.lenses.description
        , numberOfServingsLens = RecipeCreationClientInput.lenses.numberOfServings
        , updateMsg = Just >> Page.UpdateRecipeCreation
        , confirmName = "Add"
        , cancelMsg = Page.UpdateRecipeCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        }


editRecipeLineWith :
    { saveMsg : msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , descriptionLens : Lens editedValue (Maybe String)
    , numberOfServingsLens : Lens editedValue (ValidatedInput Float)
    , updateMsg : editedValue -> msg
    , confirmName : String
    , cancelMsg : msg
    , cancelName : String
    , rowStyles : List (Attribute msg)
    }
    -> editedValue
    -> Html msg
editRecipeLineWith handling editedValue =
    let
        validInput =
            List.all identity
                [ handling.nameLens.get editedValue |> ValidatedInput.isValid
                , handling.numberOfServingsLens.get editedValue |> ValidatedInput.isValid
                ]

        validatedSaveAction =
            MaybeUtil.optional validInput <| onEnter handling.saveMsg
    in
    tr handling.rowStyles
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
        , td [ Style.classes.controls ]
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
        , td [] []
        , td [] []
        ]
