module Pages.Statistics.StatisticsUtil exposing (..)

import Api.Auxiliary exposing (NutrientCode, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Dict exposing (Dict)
import Monocle.Lens exposing (Lens)


type alias ReferenceNutrientTree =
    { map : ReferenceMap
    , values : Dict NutrientCode Float
    }


type alias StatisticsEvaluation =
    { referenceTrees : List ReferenceNutrientTree
    , referenceTree : Maybe ReferenceNutrientTree
    , nutrientsSearchString : String
    }


initial : StatisticsEvaluation
initial =
    { referenceTrees = []
    , referenceTree = Nothing
    , nutrientsSearchString = ""
    }


lenses :
    { referenceTrees : Lens StatisticsEvaluation (List ReferenceNutrientTree)
    , referenceTree : Lens StatisticsEvaluation (Maybe ReferenceNutrientTree)
    , nutrientsSearchString : Lens StatisticsEvaluation String
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , referenceTree = Lens .referenceTree (\b a -> { a | referenceTree = b })
    , nutrientsSearchString = Lens .nutrientsSearchString (\b a -> { a | nutrientsSearchString = b })
    }
