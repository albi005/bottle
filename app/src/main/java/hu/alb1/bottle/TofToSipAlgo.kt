package hu.alb1.bottle

import hu.alb1.bottle.data.TofLogEntry

/**
 * Full reverse-engineered ToF log → sip volume algorithm from the LARQ Live app (v1.6.1).
 *
 * Processes a time-ordered list of [TofLogEntry] records sequentially, maintaining an
 * accumulated [BottleVolumeState] to detect intake (drink) and fill events.
 *
 * Algorithm summary per log entry:
 * 1. Polynomial regression: distance(mm) → volume(ml)
 * 2. Clamp to minVolumeLimit
 * 3. If distance >= tofMax → SKIP (sensor could not read)
 * 4. Classify: Δfill > fillThreshold → FILL,  Δdrink > drinkThreshold → INTAKE,  else → SKIP
 * 5. Update accumulated state; INTAKE events with volumeAdded > 0 become [Sip] outputs
 *
 * Parameters are configurable; defaults match the 1000ml LARQ bottle hardcoded fallback
 * coefficients from `p489fb/C9916f.java`.
 */
class TofAlgorithm(
    private val tofMax: Int = DEFAULT_TOF_MAX,
    private val drinkThresholdMl: Double = DEFAULT_DRINK_THRESHOLD_ML,
    private val fillThresholdMl: Double = DEFAULT_FILL_THRESHOLD_ML,
    private val minVolumeLimitMl: Double = DEFAULT_MIN_VOLUME_LIMIT_ML,
    private val coefficients: DoubleArray = COEFF_1000ML,
) {
    companion object {
        /** Polynomial coefficients for the 1000ml (Large) LARQ bottle. */
        val COEFF_1000ML = doubleArrayOf(
            -1.1e-6,           // c₀ · d⁴
            5.5211e-4,         // c₁ · d³
            -0.08516349,       // c₂ · d²
            -0.2839113,        // c₃ · d
            1026.71212239,     // c₄ (constant)
        )

        /** Polynomial coefficients for the 680ml (Normal) LARQ bottle. */
        val COEFF_680ML = doubleArrayOf(
            -1.19e-6,
            5.0264e-4,
            -0.06522747,
            -0.81937241,
            715.15212206,
        )

        const val DEFAULT_TOF_MAX = 250
        const val DEFAULT_DRINK_THRESHOLD_ML = 15.0
        const val DEFAULT_FILL_THRESHOLD_ML = 100.0
        const val DEFAULT_MIN_VOLUME_LIMIT_ML = 0.0
    }

    /** Convert a raw ToF distance (mm) to calculated volume (ml) using the polynomial. */
    fun distanceToVolume(distanceMm: Int): Double {
        val d = distanceMm.toDouble()
        val vol = coefficients[0] * d.pow4() +
                  coefficients[1] * d.pow3() +
                  coefficients[2] * d.pow2() +
                  coefficients[3] * d +
                  coefficients[4]
        return maxOf(vol, minVolumeLimitMl)
    }

    /** Process a time-ordered list of ToF logs, returning detected sips with volume. */
    fun processLogs(logs: List<TofLogEntry>): List<Sip> {
        val sips = mutableListOf<Sip>()
        var state: BottleVolumeState? = null

        for (log in logs.sortedBy { it.timestamp }) {
            val event = processLog(log, state)
            state = event.state
            if (event is AlgoEvent.Intake && event.volumeMl > 0.0) {
                sips.add(Sip(log.timestamp, event.volumeMl))
            }
        }

        return sips
    }

    /** Process a single ToF log entry, returning the classification and new state. */
    fun processLog(log: TofLogEntry, previousState: BottleVolumeState?): AlgoEvent {
        val d = log.distanceInMillimeter
        val prev = previousState

        val calcVolume = distanceToVolume(d)

        val lastCalcVolume = prev?.lastCalcVolumeMl ?: 0.0
        val lastCountedVolume = prev?.lastCountedVolumeMl ?: 0.0
        val lastSkippedVolume = prev?.lastSkippedVolumeMl ?: 0.0
        val prevVolumeAdded = prev?.volumeAddedMl ?: 0.0
        val prevCumulative = prev?.cumulativeCalcVolumeMl ?: 0.0
        val prevTofSkipped = prev?.tofSkipped ?: false

        // --- ToF validity check ---
        val tofSkipped = d >= tofMax

        val volumeAdded: Double
        val eventType: String
        val newLastCounted: Double
        var newLastSkipped = lastSkippedVolume

        if (tofSkipped) {
            // Sensor cannot read — keep previous state values
            volumeAdded = prevVolumeAdded
            newLastCounted = lastCountedVolume
            eventType = "skip"
        } else {
            // Classify based on deltas
            val deltaFill = calcVolume - lastCalcVolume
            val deltaDrink = lastCountedVolume - calcVolume

            if (deltaFill > fillThresholdMl) {
                eventType = "fill"
                volumeAdded = if (prevTofSkipped) {
                    maxOf(0.0, lastCountedVolume - lastSkippedVolume)
                } else {
                    0.0
                }
            } else if (deltaDrink > drinkThresholdMl) {
                eventType = "intake"
                volumeAdded = deltaDrink
            } else {
                eventType = "skip"
                volumeAdded = 0.0
                newLastSkipped = calcVolume
            }
            // All non-skipped paths update lastCountedVolume to current calcVolume
            newLastCounted = calcVolume
        }

        // Validity gate: volumeAdded <= drinkThreshold AND NOT tofSkipped
        val isValidIntake = volumeAdded <= drinkThresholdMl && !tofSkipped

        // Cumulative only increases for significant events (isValidIntake == false)
        val newCumulative = if (!isValidIntake) prevCumulative + volumeAdded else prevCumulative

        val newState = BottleVolumeState(
            lastCalcVolumeMl = calcVolume,
            lastCountedVolumeMl = newLastCounted,
            lastSkippedVolumeMl = newLastSkipped,
            volumeAddedMl = volumeAdded,
            cumulativeCalcVolumeMl = newCumulative,
            tofSkipped = tofSkipped,
            tofDistanceMm = d,
        )

        return when (eventType) {
            "fill"   -> AlgoEvent.Fill(volumeAdded, newState)
            "intake" -> AlgoEvent.Intake(volumeAdded, newState)
            else     -> AlgoEvent.Skip(if (tofSkipped) "tof_out_of_range" else "no_change", newState)
        }
    }
}

/** Accumulated state maintained across sequential ToF log entries. */
data class BottleVolumeState(
    val lastCalcVolumeMl: Double,
    val lastCountedVolumeMl: Double,
    val lastSkippedVolumeMl: Double,
    val volumeAddedMl: Double,
    val cumulativeCalcVolumeMl: Double,
    val tofSkipped: Boolean,
    val tofDistanceMm: Int,
)

/**
 * A detected sip (drink) event produced by the algorithm.
 * [timestamp] is the Unix epoch-second of the ToF log entry.
 * [volumeMl] is the volume consumed in milliliters.
 */
data class Sip(
    val timestamp: Long,
    val volumeMl: Double,
)

/** Classification of a single ToF log entry by the algorithm. */
sealed class AlgoEvent {
    abstract val state: BottleVolumeState

    data class Intake(val volumeMl: Double, override val state: BottleVolumeState) : AlgoEvent()
    data class Fill(val volumeMl: Double, override val state: BottleVolumeState) : AlgoEvent()
    data class Skip(val reason: String, override val state: BottleVolumeState) : AlgoEvent()
}

// Helpers to avoid kotlin.math.pow import (which is deprecated on Double in some contexts)
private fun Double.pow4() = this * this * this * this
private fun Double.pow3() = this * this * this
private fun Double.pow2() = this * this
