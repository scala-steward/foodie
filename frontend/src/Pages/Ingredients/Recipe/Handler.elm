module Pages.Ingredients.Recipe.Handler exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens as Lens
import Pages.Ingredients.Recipe.Page as Page
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Parent.Handler
import Pages.Util.Parent.Page
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.Editing as Editing


initialFetch : AuthorizedAccess -> RecipeId -> Cmd Page.LogicMsg
initialFetch =
    Pages.Util.Requests.fetchRecipeWith (Pages.Util.Parent.Page.GotFetchResponse >> Page.ParentMsg)


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    let
        rescale =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        Pages.Util.Requests.rescaleRecipeWith Page.GotRescaleResponse
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            (main |> Pages.Util.Parent.Page.lenses.main.parent.get |> .original |> .id)
                    )
            )

        gotRescaleResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\recipe ->
                        model
                            |> Tristate.mapMain (Lens.modify Pages.Util.Parent.Page.lenses.main.parent (recipe |> Editing.asViewWithElement))
                    )
            , Cmd.none
            )
    in
    case msg of
        Page.ParentMsg parentMsg ->
            Pages.Util.Parent.Handler.updateLogic
                { toUpdate = RecipeUpdateClientInput.from
                , idOf = .id
                , save =
                    \authorizedAccess ->
                        RecipeUpdateClientInput.to
                            >> Pages.Util.Requests.saveRecipeWith
                                Pages.Util.Parent.Page.GotSaveEditResponse
                                authorizedAccess
                            >> Just
                , delete = Pages.Util.Requests.deleteRecipeWith Pages.Util.Parent.Page.GotDeleteResponse
                , duplicate = Pages.Util.Requests.duplicateRecipeWith Pages.Util.Parent.Page.GotDuplicateResponse
                , navigateAfterDeletionAddress = Addresses.Frontend.recipes.address
                , navigateAfterDuplicationAddress = Addresses.Frontend.ingredientEditor.address
                }
                parentMsg
                model
                |> Tuple.mapSecond (Cmd.map Page.ParentMsg)

        Page.Rescale ->
            rescale

        Page.GotRescaleResponse result ->
            gotRescaleResponse result
