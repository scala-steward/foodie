module Pages.Statistics.StatisticsRequests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.ReferenceTree exposing (ReferenceTree, decoderReferenceTree)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
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
    { setError : Error -> model -> model
    , statisticsEvaluationLens : Lens model StatisticsEvaluation
    }
    -> model
    -> Result Error (List ReferenceTree)
    -> ( model, Cmd msg )
gotFetchReferenceTreesResponseWith ps model result =
    ( result
        |> Result.Extra.unpack (flip ps.setError model)
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
                    |> (ps.statisticsEvaluationLens
                            |> Compose.lensWithLens StatisticsUtil.lenses.referenceTrees
                       ).set
                        referenceNutrientTrees
            )
    , Cmd.none
    )



--todo: Clean up functions


gotFetchReferenceTreesResponseWith2 :
    { referenceTreesLens : Lens initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
    , initialToMain : initial -> Maybe main
    }
    -> Tristate.Model main initial
    -> Result Error (List ReferenceTree)
    -> ( Tristate.Model main initial, Cmd msg )
gotFetchReferenceTreesResponseWith2 ps model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
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



--todo: Clean up functions


selectReferenceMapWith :
    { statisticsEvaluationLens : Lens model StatisticsEvaluation
    }
    -> model
    -> Maybe ReferenceMapId
    -> ( model, Cmd msg )
selectReferenceMapWith ps model referenceMapId =
    ( referenceMapId
        |> Maybe.andThen (flip DictList.get ((ps.statisticsEvaluationLens |> Compose.lensWithLens StatisticsUtil.lenses.referenceTrees).get model))
        |> flip
            (ps.statisticsEvaluationLens
                |> Compose.lensWithLens StatisticsUtil.lenses.referenceTree
            ).set
            model
    , Cmd.none
    )



--todo: Clean up functions


selectReferenceMapWith2 :
    { statisticsEvaluationLens : Lens main StatisticsEvaluation
    }
    -> Tristate.Model main initial
    -> Maybe ReferenceMapId
    -> ( Tristate.Model main initial, Cmd msg )
selectReferenceMapWith2 ps model referenceMapId =
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
    { statisticsEvaluationLens : Lens model StatisticsEvaluation
    }
    -> model
    -> String
    -> ( model, Cmd msg )
setNutrientsSearchStringWith ps model string =
    ( model
        |> (ps.statisticsEvaluationLens
                |> Compose.lensWithLens StatisticsUtil.lenses.nutrientsSearchString
           ).set
            string
    , Cmd.none
    )



--todo: Clean up functions


setNutrientsSearchStringWith2 :
    { statisticsEvaluationLens : Lens main StatisticsEvaluation
    }
    -> Tristate.Model main initial
    -> String
    -> ( Tristate.Model main initial, Cmd msg )
setNutrientsSearchStringWith2 ps model string =
    ( model
        |> Tristate.mapMain
            ((ps.statisticsEvaluationLens
                |> Compose.lensWithLens StatisticsUtil.lenses.nutrientsSearchString
             ).set
                string
            )
    , Cmd.none
    )
