module Pages.Statistics.StatisticsRequests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.ReferenceTree exposing (ReferenceTree, decoderReferenceTree)
import Basics.Extra exposing (flip)
import Dict
import Http
import Json.Decode as Decode
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil as StatisticsUtil exposing (StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Result.Extra
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
                                    ( referenceTree.referenceMap.id
                                    , { map = referenceTree.referenceMap
                                      , values =
                                            referenceTree.nutrients
                                                |> List.map
                                                    (\referenceValue ->
                                                        ( referenceValue.nutrientCode, referenceValue.referenceAmount )
                                                    )
                                                |> Dict.fromList
                                      }
                                    )
                                )
                            |> Dict.fromList
                in
                model
                    |> (ps.statisticsEvaluationLens
                            |> Compose.lensWithLens StatisticsUtil.lenses.referenceTrees
                       ).set
                        referenceNutrientTrees
            )
    , Cmd.none
    )


selectReferenceMapWith :
    { statisticsEvaluationLens : Lens model StatisticsEvaluation
    }
    -> model
    -> Maybe ReferenceMapId
    -> ( model, Cmd msg )
selectReferenceMapWith ps model referenceMapId =
    ( referenceMapId
        |> Maybe.andThen (flip Dict.get ((ps.statisticsEvaluationLens |> Compose.lensWithLens StatisticsUtil.lenses.referenceTrees).get model))
        |> flip
            (ps.statisticsEvaluationLens
                |> Compose.lensWithLens StatisticsUtil.lenses.referenceTree
            ).set
            model
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
