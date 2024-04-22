module Pages.Recipes.Handler exposing (init, update)

import Addresses.Frontend
import Pages.Recipes.Page as Page
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Requests as Requests
import Pages.Util.ParentEditor.Handler
import Pages.Util.ParentEditor.Page
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.Editing as Editing
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Pages.Util.ParentEditor.Page.initial flags.authorizedAccess
    , Requests.fetchRecipes flags.authorizedAccess |> Cmd.map (Page.ParentMsg >> Tristate.Logic)
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    let
        rescale recipeId =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        Pages.Util.Requests.rescaleRecipeWith Page.GotRescaleResponse
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            recipeId
                    )
            )

        gotRescaleResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\recipe ->
                        model
                            |> Tristate.mapMain (LensUtil.updateById recipe.id Pages.Util.ParentEditor.Page.lenses.main.parents (recipe |> Editing.asViewWithElement))
                    )
            , Cmd.none
            )
    in
    case msg of
        Page.ParentMsg parentMsg ->
            Pages.Util.ParentEditor.Handler.updateLogic
                { idOfParent = .id
                , toUpdate = RecipeUpdateClientInput.from
                , navigateToAddress = Addresses.Frontend.ingredientEditor.address
                , updateCreationTimestamp = always identity
                , create = \authorizedAccess -> RecipeCreationClientInput.toCreation >> Requests.createRecipe authorizedAccess
                , save = \authorizedAccess recipeId -> RecipeUpdateClientInput.to >> Requests.saveRecipe authorizedAccess recipeId
                , delete = Requests.deleteRecipe
                , duplicate = Pages.Util.Requests.duplicateRecipeWith Pages.Util.ParentEditor.Page.GotDuplicateResponse
                , attemptInitialToMainAfterFetchResponse = True
                }
                parentMsg
                model
                |> Tuple.mapSecond (Cmd.map Page.ParentMsg)

        Page.Rescale recipeId ->
            rescale recipeId

        Page.GotRescaleResponse result ->
            gotRescaleResponse result
