module Pages.Statistics.StatisticsRequests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Profile exposing (Profile)
import Api.Types.ReferenceTree exposing (ReferenceTree, decoderReferenceTree)
import Basics.Extra exposing (flip)
import Dict
import Http
import Json.Decode as Decode
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil as StatisticsUtil exposing (ReferenceNutrientTree, StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList exposing (DictList)
import Util.HttpUtil as HttpUtil exposing (Error)


fetchReferenceTreesWith : (Result Error (List ReferenceTree) -> msg) -> AuthorizedAccess -> Cmd msg
fetchReferenceTreesWith mkMsg authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.allTrees
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson mkMsg (Decode.list decoderReferenceTree)
        }


gotFetchReferenceTreesResponseWith :
    { referenceTreesLens : Lens initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
    , initialToMain : initial -> Maybe main
    }
    -> Tristate.Model main initial
    -> Result Error (List ReferenceTree)
    -> ( Tristate.Model main initial, Cmd msg )
gotFetchReferenceTreesResponseWith ps model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\referenceTrees ->
                let
                    referenceNutrientTrees =
                        referenceTrees
                            |> List.map
                                (\referenceTree ->
                                    { map = referenceTree.referenceMap
                                    , values =
                                        referenceTree.nutrients
                                            |> List.map
                                                (\referenceValue ->
                                                    ( referenceValue.nutrientCode, referenceValue.referenceAmount )
                                                )
                                            |> Dict.fromList
                                    }
                                )
                            |> DictList.fromListWithKey (.map >> .id)
                in
                model
                    |> Tristate.mapInitial
                        (ps.referenceTreesLens.set (referenceNutrientTrees |> Just))
                    |> Tristate.fromInitToMain ps.initialToMain
            )
    , Cmd.none
    )


gotFetchProfilesResponseWith :
    { profilesLens : Lens initial (Maybe (List Profile))
    , initialToMain : initial -> Maybe main
    }
    -> Tristate.Model main initial
    -> Result Error (List Profile)
    -> ( Tristate.Model main initial, Cmd msg )
gotFetchProfilesResponseWith ps model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\profiles ->
                model
                    |> Tristate.mapInitial (ps.profilesLens.set (profiles |> Just))
                    |> Tristate.fromInitToMain ps.initialToMain
            )
    , Cmd.none
    )


selectReferenceMapWith :
    { statisticsEvaluationLens : Lens main StatisticsEvaluation
    }
    -> Tristate.Model main initial
    -> Maybe ReferenceMapId
    -> ( Tristate.Model main initial, Cmd msg )
selectReferenceMapWith ps model referenceMapId =
    ( model
        |> Tristate.mapMain
            (\main ->
                main
                    |> (referenceMapId
                            |> Maybe.andThen (flip DictList.get ((ps.statisticsEvaluationLens |> Compose.lensWithLens StatisticsUtil.lenses.referenceTrees).get main))
                            |> (ps.statisticsEvaluationLens
                                    |> Compose.lensWithLens StatisticsUtil.lenses.referenceTree
                               ).set
                       )
            )
    , Cmd.none
    )


setNutrientsSearchStringWith :
    { statisticsEvaluationLens : Lens main StatisticsEvaluation
    }
    -> Tristate.Model main initial
    -> String
    -> ( Tristate.Model main initial, Cmd msg )
setNutrientsSearchStringWith ps model string =
    ( model
        |> Tristate.mapMain
            ((ps.statisticsEvaluationLens
                |> Compose.lensWithLens StatisticsUtil.lenses.nutrientsSearchString
             ).set
                string
            )
    , Cmd.none
    )
