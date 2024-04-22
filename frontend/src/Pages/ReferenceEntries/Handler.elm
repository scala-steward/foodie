module Pages.ReferenceEntries.Handler exposing (init, update)

import Api.Types.Nutrient exposing (decoderNutrient)
import Json.Decode as Decode
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.ReferenceEntries.Entries.Handler
import Pages.ReferenceEntries.Entries.Requests
import Pages.ReferenceEntries.Map.Handler
import Pages.ReferenceEntries.Page as Page exposing (LogicMsg(..))
import Pages.Util.Choice.Page
import Pages.View.Tristate as Tristate
import Pages.View.TristateUtil as TristateUtil
import Result.Extra
import Util.DictList as DictList
import Util.HttpUtil as HttpUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess flags.referenceMapId
    , initialFetch flags |> Cmd.map Tristate.Logic
    )


initialFetch : Page.Flags -> Cmd Page.LogicMsg
initialFetch flags =
    Cmd.batch
        [ Pages.ReferenceEntries.Map.Handler.initialFetch flags.authorizedAccess flags.referenceMapId |> Cmd.map Page.MapMsg
        , Pages.ReferenceEntries.Entries.Handler.initialFetch flags.authorizedAccess flags.referenceMapId |> Cmd.map Page.EntriesMsg
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.MapMsg mapMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.map
                , mainSubModelLens = Page.lenses.main.map
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.ReferenceEntries.Map.Handler.updateLogic
                , toMsg = Page.MapMsg
                }
                mapMsg
                model

        Page.EntriesMsg entriesMsg ->
            TristateUtil.updateFromSubModel
                { initialSubModelLens = Page.lenses.initial.entries
                , mainSubModelLens = Page.lenses.main.entries
                , fromInitToMain = Page.initialToMain
                , updateSubModel = Pages.ReferenceEntries.Entries.Handler.updateLogic
                , toMsg = Page.EntriesMsg
                }
                entriesMsg
                model

        Page.UpdateNutrients string ->
            updateNutrients model string


updateNutrients : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
updateNutrients model =
    Decode.decodeString (Decode.list decoderNutrient)
        >> Result.Extra.unpack (\error -> ( error |> HttpUtil.jsonErrorToError |> Tristate.toError model, Cmd.none ))
            (\nutrients ->
                ( model
                    |> Tristate.mapInitial
                        ((Page.lenses.initial.entries
                            |> Compose.lensWithLens Pages.Util.Choice.Page.lenses.initial.choices
                         ).set
                            (nutrients
                                |> DictList.fromListWithKey .code
                                |> Just
                                |> Maybe.Extra.filter (DictList.isEmpty >> not)
                            )
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
                , model
                    |> Tristate.lenses.initial.getOption
                    |> Maybe.Extra.filter (always (List.isEmpty nutrients))
                    |> Maybe.Extra.unwrap Cmd.none
                        (\initial ->
                            Pages.ReferenceEntries.Entries.Requests.fetchNutrients
                                { configuration = model.configuration
                                , jwt = initial.jwt
                                }
                                |> Cmd.map Page.EntriesMsg
                        )
                )
            )
