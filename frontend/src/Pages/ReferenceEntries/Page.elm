module Pages.ReferenceEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Monocle.Lens exposing (Lens)
import Pages.ReferenceEntries.Entries.Page
import Pages.ReferenceEntries.Map.Page
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)


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


type alias ReferenceEntryState =
    Editing ReferenceEntry ReferenceEntryUpdateClientInput


type alias NutrientMap =
    DictList NutrientCode Nutrient


type alias AddNutrientMap =
    DictList NutrientCode ReferenceEntryCreationClientInput


type alias ReferenceEntryStateMap =
    DictList NutrientCode ReferenceEntryState


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
