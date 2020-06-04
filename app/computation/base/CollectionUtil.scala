package base

import algebra.ring.AdditiveMonoid
import spire.implicits._

object CollectionUtil {

  def sum[A: AdditiveMonoid](xs: Traversable[A]): A = xs.foldLeft(AdditiveMonoid[A].zero)(_ + _)

}
