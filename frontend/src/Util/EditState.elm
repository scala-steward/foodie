module Util.EditState exposing (EditState(..), lenses, unpack)

import Monocle.Optional exposing (Optional)


type EditState update
    = View
    | Update update
    | Delete


lenses :
    { update : Optional (EditState update) update
    }
lenses =
    { update = Optional toUpdate setUpdate
    }


unpack :
    { onView : a
    , onUpdate : update -> a
    , onDelete : a
    }
    -> EditState update
    -> a
unpack fs editState =
    case editState of
        View ->
            fs.onView

        Update update ->
            fs.onUpdate update

        Delete ->
            fs.onDelete


toUpdate : EditState update -> Maybe update
toUpdate editState =
    case editState of
        Update update ->
            Just update

        _ ->
            Nothing


setUpdate : update -> EditState update -> EditState update
setUpdate update editState =
    case editState of
        Update _ ->
            Update update

        e ->
            e
