module Pages.Statistics.StatisticsLenses exposing (..)

import Api.Types.FoodNutrientInformation exposing (FoodNutrientInformation)
import Api.Types.FoodStats exposing (FoodStats)
import Api.Types.TotalOnlyNutrientInformation exposing (TotalOnlyNutrientInformation)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens exposing (Lens)


foodStatsNutrients : Lens FoodStats (List FoodNutrientInformation)
foodStatsNutrients =
    Lens .nutrients (\b a -> { a | nutrients = b })


totalOnlyStatsNutrients : Lens TotalOnlyStats (List TotalOnlyNutrientInformation)
totalOnlyStatsNutrients =
    Lens .nutrients (\b a -> { a | nutrients = b })
