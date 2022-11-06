module Util.Editing exposing (..)

import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Util.EditState as EditState exposing (EditState)


type alias Editing original update =
    { original : original
    , editState : EditState update
    }


lenses :
    { editState : Lens (Editing original update) (EditState update)
    , update : Optional (Editing original update) update
    }
lenses =
    let
        editState =
            Lens .editState (\b a -> { a | editState = b })
    in
    { editState = editState
    , update =
        editState
            |> Compose.lensWithOptional EditState.lenses.update
    }


unpack :
    { onView : original -> a
    , onUpdate : original -> update -> a
    , onDelete : original -> a
    }
    -> Editing original update
    -> a
unpack fs editing =
    EditState.unpack
        { onView = fs.onView editing.original
        , onUpdate = fs.onUpdate editing.original
        , onDelete = fs.onDelete editing.original
        }
        editing.editState


viewToUpdate : (original -> update) -> Editing original update -> Editing original update
viewToUpdate to editing =
    lenses.editState.set
        (EditState.unpack
            { onView = editing.original |> to |> EditState.Update
            , onUpdate = EditState.Update
            , onDelete = EditState.Delete
            }
            editing.editState
        )
        editing


viewToDelete : Editing original update -> Editing original update
viewToDelete editing =
    lenses.editState.set
        (EditState.unpack
            { onView = EditState.Delete
            , onUpdate = EditState.Update
            , onDelete = EditState.Delete
            }
            editing.editState
        )
        editing


anyToView : Editing original update -> Editing original update
anyToView editing =
    lenses.editState.set
        (EditState.unpack
            { onView = EditState.View
            , onUpdate = EditState.View |> always
            , onDelete = EditState.View
            }
            editing.editState
        )
        editing


extractUpdate : Editing original update -> Maybe update
extractUpdate =
    lenses.editState
        |> Compose.lensWithOptional EditState.lenses.update
        |> .getOption


asView : element -> Editing element update
asView element =
    { original = element
    , editState = EditState.View
    }
