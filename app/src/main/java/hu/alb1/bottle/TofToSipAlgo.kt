@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import hu.alb1.bottle.data.TofLogEntry
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

fun tofToSip(tofs: List<TofLogEntry>): List<Sip> {

}

data class Sip(val time: Instant, val volumeMl: Double)