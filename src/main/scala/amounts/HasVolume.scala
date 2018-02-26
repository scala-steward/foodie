package amounts

import physical.{Litre, NamedUnit, Prefix}

trait HasVolume[N, P <: Prefix] {
  def volume: NamedUnit[N, P, Litre]
}