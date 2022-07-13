package controllers.stats

import io.circe.generic.JsonCodec

import java.util.Date

@JsonCodec
case class StatsRequest(
    from: Date,
    to: Date
)
