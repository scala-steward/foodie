module Pages.Util.Choice.ChoiceGroup exposing (..)

import Api.Auxiliary exposing (JWT)
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
type alias Model parentId elementId element update choiceId choice creation =
    Tristate.Model (Main parentId elementId element update choiceId choice creation) (Initial parentId elementId element choiceId choice)


type alias Main parentId elementId element update choiceId choice creation =
    { jwt : JWT
    , parentId : parentId
    , elements : DictList elementId (Editing element update)
    , choices : DictList choiceId (Editing choice creation)
    , pagination : Pagination
    , choicesSearchString : String
    , elementsSearchString : String
    }


type alias Initial parentId elementId element choiceId choice =
    { jwt : JWT
    , parentId : parentId
    , elements : Maybe (DictList elementId element)
    , choices : Maybe (DictList choiceId choice)
    }


initialWith : JWT -> parentId -> Initial parentId elementId element choiceId choice
initialWith jwt parentId =
    { jwt = jwt
    , parentId = parentId
    , elements = Nothing
    , choices = Nothing
    }


initialToMain : Initial parentId elementId element choiceId choice -> Maybe (Main parentId elementId element update choiceId choice creation)
initialToMain i =
    Maybe.map2
        (\elements choices ->
            { jwt = i.jwt
            , parentId = i.parentId
            , elements = elements |> DictList.map Editing.asView
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
        { elements : Lens (Initial parentId elementId element choiceId choice) (Maybe (DictList elementId element))
        , choices : Lens (Initial parentId elementId element choiceId choice) (Maybe (DictList choiceId choice))
        }
    , main :
        { elements : Lens (Main parentId elementId element update choiceId choice creation) (DictList elementId (Editing element update))
        , choices : Lens (Main parentId elementId element update choiceId choice creation) (DictList choiceId (Editing choice creation))
        , pagination : Lens (Main parentId elementId element update choiceId choice creation) Pagination
        , choicesSearchString : Lens (Main parentId elementId element update choiceId choice creation) String
        , elementsSearchString : Lens (Main parentId elementId element update choiceId choice creation) String
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
