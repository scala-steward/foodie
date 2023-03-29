module Pages.Util.Choice.ChoiceGroup exposing (..)

import Api.Auxiliary exposing (JWT, RecipeId)
import Monocle.Lens exposing (Lens)
import Pages.Util.Choice.Pagination as Pagination exposing (Pagination)
import Pages.View.Tristate as Tristate
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


{-|

  - elements are the values
  - elements are chosen from a given list of choices
  - a choice is made via a creation, i.e. 'creation' turns a choice into an element
  - an element can be updated with an 'update'
  - elements (may) belong to a parent

-}
type alias Model elementId element update choiceId choice creation =
    Tristate.Model (Main elementId element update choiceId choice creation) (Initial elementId element update choiceId choice)


type alias Main elementId element update choiceId choice creation =
    { jwt : JWT
    , recipeId : RecipeId
    , elements : DictList elementId (Editing element update)
    , choices : DictList choiceId (Editing choice creation)
    , pagination : Pagination
    , choicesSearchString : String
    , elementsSearchString : String
    }



-- todo: Remove update, it should be processed while turning Initial into Main


type alias Initial elementId element update choiceId choice =
    { jwt : JWT
    , recipeId : RecipeId
    , elements : Maybe (DictList elementId (Editing element update))
    , choices : Maybe (DictList choiceId choice)
    }


initialWith : JWT -> RecipeId -> Initial elementId element update choiceId choice
initialWith jwt recipeId =
    { jwt = jwt
    , recipeId = recipeId
    , elements = Nothing
    , choices = Nothing
    }


initialToMain : Initial elementId element update choiceId choice -> Maybe (Main elementId element update choiceId choice creation)
initialToMain i =
    Maybe.map2
        (\elements choices ->
            { jwt = i.jwt
            , recipeId = i.recipeId
            , elements = elements
            , choices = choices |> DictList.map Editing.asView
            , pagination = Pagination.initial
            , choicesSearchString = ""
            , elementsSearchString = ""
            }
        )
        i.elements
        i.choices


lenses :
    { initial :
        { elements : Lens (Initial elementId element update choiceId choice) (Maybe (DictList elementId (Editing element update)))
        , choices : Lens (Initial elementId element update choiceId choice) (Maybe (DictList choiceId choice))
        }
    , main :
        { elements : Lens (Main elementId element update choiceId choice creation) (DictList elementId (Editing element update))
        , choices : Lens (Main elementId element update choiceId choice creation) (DictList choiceId (Editing choice creation))
        , pagination : Lens (Main elementId element update choiceId choice creation) Pagination
        , choicesSearchString : Lens (Main elementId element update choiceId choice creation) String
        , elementsSearchString : Lens (Main elementId element update choiceId choice creation) String
        }
    }
lenses =
    { initial =
        { elements = Lens .elements (\b a -> { a | elements = b })
        , choices = Lens .choices (\b a -> { a | choices = b })
        }
    , main =
        { elements = Lens .elements (\b a -> { a | elements = b })
        , choices = Lens .choices (\b a -> { a | choices = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        , choicesSearchString = Lens .choicesSearchString (\b a -> { a | choicesSearchString = b })
        , elementsSearchString = Lens .elementsSearchString (\b a -> { a | elementsSearchString = b })
        }
    }


type LogicMsg elementId element update choiceId choice creation
    = Edit update
    | SaveEdit update
    | GotSaveEditResponse (Result Error element)
    | ToggleControls elementId
    | EnterEdit elementId
    | ExitEdit elementId
    | RequestDelete elementId
    | ConfirmDelete elementId
    | CancelDelete elementId
    | GotDeleteResponse elementId (Result Error ())
    | GotFetchElementsResponse (Result Error (List element))
    | GotFetchChoicesResponse (Result Error (List choice))
    | ToggleChoiceControls choiceId
    | SelectChoice choice
    | DeselectChoice choiceId
    | Create choiceId
    | GotCreateResponse (Result Error element)
    | UpdateCreation creation
    | SetPagination Pagination
    | SetElementsSearchString String
    | SetChoicesSearchString String
