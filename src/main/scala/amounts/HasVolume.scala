package amounts

import physical.{Litre, NamedUnit}

trait HasVolume[N, P] {
  def volume: NamedUnit[N, P, Litre]
}