package base

import algebra.ring.{AdditiveGroup, AdditiveSemigroup}
import physical.NamedUnit.Implicits._
import physical.NamedUnitAnyPrefix.Implicits._
import physical.{NamedUnit, PUnit, Prefix}
import spire.algebra.{AdditiveAbGroup, AdditiveMonoid, Module}
import spire.math.Numeric

object FunctionalAnyPrefix {

  object Implicits {

    implicit def fapASG[A, N: Numeric, U: PUnit]: AdditiveSemigroup[Functional[NamedUnit[N, _ <: Prefix, U], A]] = fapM

    implicit def fapAM[A, N: Numeric, U: PUnit]: AdditiveMonoid[Functional[NamedUnit[N, _ <: Prefix, U], A]] = fapM

    implicit def fapAG[A, N: Numeric, U: PUnit]: AdditiveGroup[Functional[NamedUnit[N, _ <: Prefix, U], A]] = fapM

    implicit def fapAAG[A, N: Numeric, U: PUnit]: AdditiveAbGroup[Functional[NamedUnit[N, _ <: Prefix, U], A]] = fapM

    implicit def fapM[A, N: Numeric, U: PUnit]: Module[Functional[NamedUnit[N, _ <: Prefix, U], A], N] =
      Functional.Implicits.moduleF[NamedUnit[N, _ <: Prefix, U], A, N]
  }

}
