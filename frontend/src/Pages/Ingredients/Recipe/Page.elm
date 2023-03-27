module Pages.Ingredients.Recipe.Page exposing (..)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.View.Tristate as Tristate
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipe : Editing Recipe RecipeUpdateClientInput
    }


type alias Initial =
    { jwt : JWT
    , recipe : Maybe (Editing Recipe RecipeUpdateClientInput)
    }


initialWith : JWT -> Initial
initialWith jwt =
    { jwt = jwt
    , recipe = Nothing
    }


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.recipe
        |> Maybe.map
            (\recipe ->
                { jwt = i.jwt
                , recipe = recipe
                }
            )


lenses :
    { initial :
        { recipe : Lens Initial (Maybe (Editing Recipe RecipeUpdateClientInput))
        }
    , main :
        { recipe : Lens Main (Editing Recipe RecipeUpdateClientInput)
        }
    }
lenses =
    { initial =
        { recipe = Lens .recipe (\b a -> { a | recipe = b })
        }
    , main =
        { recipe = Lens .recipe (\b a -> { a | recipe = b })
        }
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = GotFetchResponse (Result Error Recipe)
    | Edit RecipeUpdateClientInput
    | SaveEdit
    | GotSaveEditResponse (Result Error Recipe)
    | EnterEdit
    | ExitEdit
    | RequestDelete
    | ConfirmDelete
    | CancelDelete
    | GotDeleteResponse (Result Error ())
    | ToggleControls
