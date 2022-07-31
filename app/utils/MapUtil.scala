package utils

object MapUtil {

  def unionWith[K, A](map1: Map[K, A], map2: Map[K, A])(union: (A, A) => A): Map[K, A] = {
    val allKeys = map1.keySet ++ map2.keySet
    allKeys.flatMap { key =>
      val value = (map1.get(key), map2.get(key)) match {
        case (Some(v1), Some(v2)) => Some(union(v1, v2))
        case (v1 @ Some(_), _)    => v1
        case (_, v2)              => v2
      }
      value.map(key -> _)
    }.toMap
  }

}
