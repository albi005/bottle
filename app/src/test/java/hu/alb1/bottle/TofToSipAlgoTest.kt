package hu.alb1.bottle

import hu.alb1.bottle.data.TofLogEntry
import hu.alb1.bottle.proto.CapEnumTofTriggerType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TofToSipAlgoTest {

    private val algo = TofAlgorithm()

    // --- Polynomial regression ---

    @Test
    fun `distance 0 gives approximately full bottle volume`() {
        val vol = algo.distanceToVolume(0)
        assertEquals(1026.71, vol, 0.1) // ~1027ml = nominal full
    }

    @Test
    fun `distance 100 gives around half-full volume`() {
        val vol = algo.distanceToVolume(100)
        // ~589 ml — roughly half
        assertTrue(vol in 500.0..700.0)
    }

    @Test
    fun `distance 200 gives near-empty volume`() {
        val vol = algo.distanceToVolume(200)
        assertTrue(vol in 100.0..300.0)
    }

    @Test
    fun `volume decreases monotonically with distance for realistic range`() {
        var prev = algo.distanceToVolume(0)
        for (d in 1..200 step 10) {
            val curr = algo.distanceToVolume(d)
            assertTrue("at d=$d: $curr > $prev", curr < prev)
            prev = curr
        }
    }

    // --- Single intake detection ---

    @Test
    fun `single drink from full bottle produces one intake event`() {
        // Full bottle: distance = 0 → ~1027ml
        // Drink ~200ml: now distance ≈ 55mm → ~822ml
        val entries = listOf(
            tofLog(0, 0),   // full
            tofLog(55, 10), // after drinking
        )

        val sips = algo.processLogs(entries)
        assertEquals(1, sips.size)
        val sip = sips[0]
        assertTrue("volume ${sip.volumeMl} > 100", sip.volumeMl > 100.0)
        assertTrue("volume ${sip.volumeMl} < 250", sip.volumeMl < 250.0)
    }

    @Test
    fun `tiny distance change below threshold is not an intake`() {
        // 1mm change → negligible volume delta
        val entries = listOf(
            tofLog(50, 0),
            tofLog(51, 10), // barely moved
        )

        val sips = algo.processLogs(entries)
        assertEquals(0, sips.size)
    }

    @Test
    fun `large change above threshold IS an intake`() {
        val entries = listOf(
            tofLog(0, 0),   // ~1027ml
            tofLog(80, 10), // ~710ml — drank ~317ml
        )

        val sips = algo.processLogs(entries)
        assertEquals(1, sips.size)
        assertTrue("large sip", sips[0].volumeMl > 200.0)
    }

    // --- Fill detection ---

    @Test
    fun `fill event is not reported as intake`() {
        // Start partially empty, then fill back up (distance decreases = more liquid)
        val entries = listOf(
            tofLog(100, 0), // ~589ml
            tofLog(0, 10),   // back to full ~1027ml → this is a fill, not a drink
        )

        val sips = algo.processLogs(entries)
        assertEquals(0, sips.size)
    }

    @Test
    fun `fill followed by drink produces one intake for the drink`() {
        val entries = listOf(
            tofLog(0, 0),    // full
            tofLog(100, 10), // drank ~438ml
            tofLog(0, 20),   // refill (FILL)
            tofLog(50, 30),  // drank ~165ml
        )

        val sips = algo.processLogs(entries)
        // Two drink events (log at t=10 and t=30), no fill
        assertEquals(2, sips.size)
    }

    // --- ToF skip (out of range) ---

    @Test
    fun `tof reading beyond max is skipped`() {
        val algo = TofAlgorithm(tofMax = 150)
        // d=999 > tofMax → event is Skip, no intake produced
        val entries = listOf(
            tofLog(50, 0),
            tofLog(999, 10), // > tofMax → skip
        )

        val results = mutableListOf<AlgoEvent>()
        var state: BottleVolumeState? = null
        for (log in entries) {
            val event = algo.processLog(log, state)
            state = event.state
            results.add(event)
        }
        assertTrue(results[1] is AlgoEvent.Skip)
    }

    @Test
    fun `fill takes priority over intake when coming back from tof skip`() {
        // LARQ algo checks FILL before INTAKE. After a tof skip that records an
        // artificially low calcVolume, the next valid reading with more water
        // (lower distance) will register as FILL, not a massive intake.
        val algo = TofAlgorithm(tofMax = 200)
        val entries = listOf(
            tofLog(50, 0),    // ~862ml, initial (FILL from zero)
            tofLog(100, 10),  // ~589ml, drink ~273ml (INTAKE)
            tofLog(999, 20),  // tof skip (carries forward volumeAdded)
            tofLog(120, 30),  // ~458ml → FILL (deltaFill=492 > 100)
        )

        val sips = algo.processLogs(entries)
        assertEquals(1, sips.size) // only the drink at t=10
        assertEquals(273.0, sips[0].volumeMl, 1.0)
    }

    @Test
    fun `consecutive tof skips assign zero volume`() {
        val algo = TofAlgorithm(tofMax = 100)
        val entries = listOf(
            tofLog(50, 0),
            tofLog(999, 10), // skip
            tofLog(999, 20), // skip again
        )

        val sips = algo.processLogs(entries)
        assertEquals(0, sips.size)
    }

    // --- Fill after ToF skip ---

    @Test
    fun `fill after tof skip captures delta from last skipped volume`() {
        // When the sensor was out of range, a subsequent fill should account
        // for the volume that was "missing" during the skip period.
        val algo = TofAlgorithm(tofMax = 120)
        val entries = listOf(
            tofLog(50, 0),    // ~862ml, normal reading
            tofLog(55, 10),   // drank a bit
            tofLog(999, 20),  // tof skipped
            tofLog(0, 30),    // refill registered → FILL
            tofLog(55, 40),   // drink after fill
        )

        val sips = algo.processLogs(entries)
        // Should have 2 intakes: drink at t=10 and drink at t=40
        assertEquals(2, sips.size)
    }

    // --- Multiple sequential intakes ---

    @Test
    fun `multiple sequential drinks are all detected`() {
        val entries = (0..4).map { i ->
            val dist = (i * 40) + 20  // 20, 60, 100, 140, 180mm
            tofLog(dist, i * 10L)
        }

        val sips = algo.processLogs(entries)
        // Each step is ~140ml decrease — all should be detected
        assertEquals(4, sips.size)
    }

    @Test
    fun `cumulative volume of sequential drinks decreases`() {
        val entries = listOf(
            tofLog(0, 0),
            tofLog(40, 10),
            tofLog(80, 20),
            tofLog(120, 30),
        )

        val results = mutableListOf<AlgoEvent>()
        var state: BottleVolumeState? = null
        for (log in entries) {
            val event = algo.processLog(log, state)
            state = event.state
            results.add(event)
        }

        // Cumulative should be ≥ sum of intakes
        val totalIntake = results.filterIsInstance<AlgoEvent.Intake>().sumOf { it.volumeMl }
        val finalCumulative = results.last().state.cumulativeCalcVolumeMl
        assertEquals(totalIntake, finalCumulative, 0.01)
    }

    // --- Edge cases ---

    @Test
    fun `empty log list returns no sips`() {
        assertEquals(0, algo.processLogs(emptyList()).size)
    }

    @Test
    fun `single log entry returns no sips`() {
        assertEquals(0, algo.processLogs(listOf(tofLog(50, 0))).size)
    }

    @Test
    fun `minVolumeLimit clamps negative polynomial results`() {
        val algo = TofAlgorithm(minVolumeLimitMl = 50.0)
        val vol = algo.distanceToVolume(250) // polynomial would give ~50ml, clamped
        assertTrue(vol >= 50.0)
    }

    // --- SIP trigger type handling ---

    @Test
    fun `sip trigger type is treated the same as other triggers for volume`() {
        val entries = listOf(
            tofLog(0, 0, CapEnumTofTriggerType.TYPE_REQUEST),
            tofLog(60, 10, CapEnumTofTriggerType.TYPE_CAP_ON_FLAP_OPEN_SIP), // "sip" trigger
        )

        val sips = algo.processLogs(entries)
        assertEquals(1, sips.size)
        // Volume should be the same regardless of trigger type (only distance matters)
        val entries2 = listOf(
            tofLog(0, 0, CapEnumTofTriggerType.TYPE_REQUEST),
            tofLog(60, 10, CapEnumTofTriggerType.TYPE_INTERVAL),
        )
        val sips2 = algo.processLogs(entries2)
        assertEquals(1, sips2.size)
        assertEquals(sips[0].volumeMl, sips2[0].volumeMl, 0.01)
    }

    // --- State round-trip ---

    @Test
    fun `state round-trips correctly through processLog`() {
        val entries = listOf(
            tofLog(0, 0),
            tofLog(80, 10),
            tofLog(150, 20),
        )

        var state: BottleVolumeState? = null
        for (log in entries) {
            val event = algo.processLog(log, state)
            state = event.state
        }

        val last = state!!
        assertEquals(150, last.tofDistanceMm)
        assertTrue(last.cumulativeCalcVolumeMl > 0.0)
    }

    // --- Helpers ---

    private fun tofLog(
        distanceMm: Int,
        timestamp: Long,
        triggerType: CapEnumTofTriggerType = CapEnumTofTriggerType.TYPE_REQUEST,
    ) = TofLogEntry(
        timestamp = timestamp,
        triggerType = triggerType,
        distanceInMillimeter = distanceMm,
        kcps = 100,
        uvLedTempInOhm = 0f,
    )
}
