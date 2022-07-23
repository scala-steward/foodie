package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class StatsRequest(
    // TODO: Use sensible date type
    from: Long,
    to: Long
)
