package computation.amounts

import computation.physical.{Litre, NamedUnit}

trait HasVolume[N] {
  def volume: NamedUnit[N, Litre]
}