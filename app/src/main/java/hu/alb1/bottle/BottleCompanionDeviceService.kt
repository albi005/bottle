package hu.alb1.bottle

import android.companion.CompanionDeviceService
import android.companion.DevicePresenceEvent

class BottleCompanionDeviceService : CompanionDeviceService() {
    override fun onDevicePresenceEvent(event: DevicePresenceEvent) {
        super.onDevicePresenceEvent(event)
    }
}