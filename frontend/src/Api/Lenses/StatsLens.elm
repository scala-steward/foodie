module Api.Lenses.StatsLens exposing (..)

import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.Stats exposing (Stats)
import Monocle.Lens exposing (Lens)


nutrients : Lens Stats (List NutrientInformation)
nutrients =
    Lens .nutrients (\b a -> { a | nutrients = b })
