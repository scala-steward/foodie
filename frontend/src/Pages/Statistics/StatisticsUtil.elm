module Pages.Statistics.StatisticsUtil exposing (..)

import Api.Auxiliary exposing (NutrientCode, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Dict exposing (Dict)
import Monocle.Lens exposing (Lens)
import Util.DictList as DictList exposing (DictList)


type alias ReferenceNutrientTree =
    { map : ReferenceMap
    , values : Dict NutrientCode Float
    }


type alias StatisticsEvaluation =
    { referenceTrees : DictList ReferenceMapId ReferenceNutrientTree
    , referenceTree : Maybe ReferenceNutrientTree
    , nutrientsSearchString : String
    }


initial : StatisticsEvaluation
initial =
    { referenceTrees = DictList.empty
    , referenceTree = Nothing
    , nutrientsSearchString = ""
    }


lenses :
    { referenceTrees : Lens StatisticsEvaluation (DictList ReferenceMapId ReferenceNutrientTree)
    , referenceTree : Lens StatisticsEvaluation (Maybe ReferenceNutrientTree)
    , nutrientsSearchString : Lens StatisticsEvaluation String
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , referenceTree = Lens .referenceTree (\b a -> { a | referenceTree = b })
    , nutrientsSearchString = Lens .nutrientsSearchString (\b a -> { a | nutrientsSearchString = b })
    }
