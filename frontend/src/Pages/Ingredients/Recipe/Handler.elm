module Pages.Ingredients.Recipe.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Pages.Ingredients.Recipe.Page as Page
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Links as Links
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.Editing as Editing
import Util.HttpUtil exposing (Error)


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch authorizedAccess recipeId =
    Pages.Util.Requests.fetchRecipeWith Page.GotFetchResponse
        { authorizedAccess = authorizedAccess
        , recipeId = recipeId
        }


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.GotFetchResponse result ->
            gotFetchResponse model result

        Page.ToggleControls ->
            toggleControls model

        Page.Edit recipeUpdateClientInput ->
            edit model recipeUpdateClientInput

        Page.SaveEdit ->
            saveEdit model

        Page.GotSaveEditResponse result ->
            gotSaveEditResponse model result

        Page.EnterEdit ->
            enterEdit model

        Page.ExitEdit ->
            exitEdit model

        Page.RequestDelete ->
            requestDelete model

        Page.ConfirmDelete ->
            confirmDelete model

        Page.CancelDelete ->
            cancelDelete model

        Page.GotDeleteResponse result ->
            gotDeleteResponse model result


gotFetchResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipe ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.recipe.set (recipe |> Editing.asView |> Just))
            )
    , Cmd.none
    )


toggleControls : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
toggleControls model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.recipe Editing.toggleControls)
    , Cmd.none
    )


edit : Page.Model -> RecipeUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
edit model recipeUpdateClientInput =
    ( model
        |> Tristate.mapMain
            ((Page.lenses.main.recipe
                |> Compose.lensWithOptional Editing.lenses.update
             ).set
                recipeUpdateClientInput
            )
    , Cmd.none
    )


saveEdit : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
saveEdit model =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> Page.lenses.main.recipe.get
                    |> Editing.extractUpdate
                    |> Maybe.map
                        (RecipeUpdateClientInput.to
                            >> (\recipeUpdate ->
                                    Pages.Util.Requests.saveRecipeWith
                                        Page.GotSaveEditResponse
                                        { authorizedAccess =
                                            { configuration = model.configuration
                                            , jwt = main.jwt
                                            }
                                        , recipeUpdate = recipeUpdate
                                        }
                               )
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotSaveEditResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.LogicMsg )
gotSaveEditResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipe ->
                model
                    |> Tristate.mapMain (Page.lenses.main.recipe.set (recipe |> Editing.asView))
            )
    , Cmd.none
    )


enterEdit : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
enterEdit model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.recipe (Editing.toUpdate RecipeUpdateClientInput.from))
    , Cmd.none
    )


exitEdit : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
exitEdit model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.recipe Editing.toView)
    , Cmd.none
    )


requestDelete : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
requestDelete model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.recipe Editing.toDelete)
    , Cmd.none
    )


confirmDelete : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
confirmDelete model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Pages.Util.Requests.deleteRecipeWith Page.GotDeleteResponse
                    { authorizedAccess =
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                    , recipeId = main.recipe.original.id
                    }
            )
    )


cancelDelete : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
cancelDelete model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.recipe Editing.toView)
    , Cmd.none
    )


gotDeleteResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
            (\_ ->
                ( model
                , Links.loadFrontendPage
                    model.configuration
                    (() |> Addresses.Frontend.recipes.address)
                )
            )
