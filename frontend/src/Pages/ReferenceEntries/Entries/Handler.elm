module Pages.ReferenceEntries.Entries.Handler exposing (..)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Nutrient exposing (encoderNutrient)
import Json.Encode as Encode
import Pages.ReferenceEntries.Entries.Page as Page
import Pages.ReferenceEntries.Entries.Requests as Requests
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler
import Ports


initialFetch : AuthorizedAccess -> ReferenceMapId -> Cmd Page.LogicMsg
initialFetch authorizedAccess referenceMapId =
    Cmd.batch
        [ Requests.fetchReferenceEntries authorizedAccess referenceMapId
        , Ports.doFetchNutrients ()
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .nutrientCode
        , idOfUpdate = .nutrientCode
        , idOfChoice = .code
        , choiceIdOfElement = .nutrientCode
        , choiceIdOfCreation = .nutrientCode
        , toUpdate = ReferenceEntryUpdateClientInput.from
        , toCreation = \nutrient -> ReferenceEntryCreationClientInput.default nutrient.code
        , createElement = \authorizedAccess referenceMapId -> ReferenceEntryCreationClientInput.toCreation referenceMapId >> Requests.createReferenceEntry authorizedAccess
        , saveElement =
            \authorizedAccess referenceMapId update ->
                ReferenceEntryUpdateClientInput.to referenceMapId update
                    |> Requests.saveReferenceEntry authorizedAccess
        , deleteElement = Requests.deleteReferenceEntry
        , storeChoices =
            Encode.list encoderNutrient
                >> Encode.encode 0
                >> Ports.storeNutrients
        }
