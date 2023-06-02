module Pages.ReferenceEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Monocle.Lens exposing (Lens)
import Pages.ReferenceEntries.Entries.Page
import Pages.ReferenceEntries.Map.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , map : Pages.ReferenceEntries.Map.Page.Main
    , entries : Pages.ReferenceEntries.Entries.Page.Main
    }


type alias Initial =
    { jwt : JWT
    , map : Pages.ReferenceEntries.Map.Page.Initial
    , entries : Pages.ReferenceEntries.Entries.Page.Initial
    }


initial : AuthorizedAccess -> ReferenceMapId -> Model
initial authorizedAccess referenceMapId =
    { jwt = authorizedAccess.jwt
    , map = Pages.Util.Parent.Page.initialWith authorizedAccess.jwt
    , entries = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt referenceMapId
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.entries
        |> Pages.Util.Choice.Page.initialToMain
        |> Maybe.andThen
            (\entries ->
                i.map
                    |> Pages.Util.Parent.Page.initialToMain
                    |> Maybe.map
                        (\map ->
                            { jwt = i.jwt
                            , map = map
                            , entries = entries
                            }
                        )
            )


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    }


lenses :
    { initial :
        { map : Lens Initial Pages.ReferenceEntries.Map.Page.Initial
        , entries : Lens Initial Pages.ReferenceEntries.Entries.Page.Initial
        }
    , main :
        { map : Lens Main Pages.ReferenceEntries.Map.Page.Main
        , entries : Lens Main Pages.ReferenceEntries.Entries.Page.Main
        }
    }
lenses =
    { initial =
        { map = Lens .map (\b a -> { a | map = b })
        , entries = Lens .entries (\b a -> { a | entries = b })
        }
    , main =
        { map = Lens .map (\b a -> { a | map = b })
        , entries = Lens .entries (\b a -> { a | entries = b })
        }
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = MapMsg Pages.ReferenceEntries.Map.Page.LogicMsg
    | EntriesMsg Pages.ReferenceEntries.Entries.Page.LogicMsg
    | UpdateNutrients String
