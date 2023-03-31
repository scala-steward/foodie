module Pages.Recipes.Handler exposing (init, update)

import Addresses.Frontend
import Api.Types.Recipe exposing (Recipe)
import Pages.Recipes.Page as Page exposing (RecipeState)
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Requests as Requests
import Pages.Util.ParentEditor.Handler
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Pages.Util.ParentEditor.Page.initial flags.authorizedAccess
    , Requests.fetchRecipes flags.authorizedAccess |> Cmd.map Tristate.Logic
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.ParentEditor.Handler.updateLogic
        { idOfParent = .id
        , idOfUpdate = .id
        , toUpdate = RecipeUpdateClientInput.from
        , navigateToAddress = Addresses.Frontend.ingredientEditor.address
        , create = \authorizedAccess -> RecipeCreationClientInput.toCreation >> Requests.createRecipe authorizedAccess
        , save = \authorizedAccess -> RecipeUpdateClientInput.to >> Requests.saveRecipe authorizedAccess
        , delete = Requests.deleteRecipe
        }
