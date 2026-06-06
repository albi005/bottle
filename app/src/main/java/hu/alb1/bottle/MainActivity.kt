package hu.alb1.bottle

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.companion.AssociationInfo
import android.companion.AssociationRequest
import android.companion.BluetoothLeDeviceFilter
import android.companion.CompanionDeviceManager
import android.companion.ObservingDevicePresenceRequest
import android.content.IntentSender
import android.content.pm.PackageManager
import android.net.MacAddress
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewScreenSizes
import androidx.core.app.ActivityCompat
import androidx.core.content.getSystemService
import hu.alb1.bottle.ui.page.DeviceListPage
import hu.alb1.bottle.ui.theme.BottleTheme
import java.util.concurrent.Executor
import java.util.regex.Pattern

private const val SELECT_DEVICE_REQUEST_CODE = 0

class MainActivity : ComponentActivity() {
    private val companionDeviceManager by lazy {
        getSystemService(COMPANION_DEVICE_SERVICE) as CompanionDeviceManager
    }
    val mBluetoothAdapter: BluetoothAdapter by lazy {
        getSystemService<BluetoothManager>()!!.adapter
    }
    val executor: Executor = Executor { it.run() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BottleTheme {
                BottleApp()
            }
        }

        val namePattern = Pattern.compile("^LARQ_")
        val deviceFilter = BluetoothLeDeviceFilter.Builder()
            .setNamePattern(namePattern)
            .build()
        val pairingRequest = AssociationRequest.Builder()
            .addDeviceFilter(deviceFilter)
            .build()
        val executor = Executor { it.run() }
        // When the app tries to pair with a Bluetooth device, show the
        // corresponding dialog box to the user.
        val aaaaaaa = companionDeviceManager.myAssociations.map { it.systemDataSyncFlags }
        companionDeviceManager.associate(
            pairingRequest,
            executor,
            object : CompanionDeviceManager.Callback() {
                // Called when a device is found. Launch the IntentSender so the user
                // can select the device they want to pair with.
                override fun onAssociationPending(intentSender: IntentSender) {
                    startIntentSenderForResult(intentSender, SELECT_DEVICE_REQUEST_CODE, null, 0, 0, 0)
                }

                override fun onAssociationCreated(associationInfo: AssociationInfo) {
                    // AssociationInfo object is created and get association id and the
                    // macAddress.
                    var associationId: Int = associationInfo.id
                    if (ActivityCompat.checkSelfPermission(
                            this@MainActivity,
                            Manifest.permission.BLUETOOTH_CONNECT
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        // TODO: Consider calling
                        //    ActivityCompat#requestPermissions
                        // here to request the missing permissions, and then overriding
                        //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
                        //                                          int[] grantResults)
                        // to handle the case where the user grants the permission. See the documentation
                        // for ActivityCompat#requestPermissions for more details.
                        return
                    }
                    val succ = associationInfo.associatedDevice!!.bleDevice!!.device.createBond()
                    companionDeviceManager.startObservingDevicePresence(
                        ObservingDevicePresenceRequest.Builder()
                            .setAssociationId(associationId)
                            .build()
                    )
                    var macAddress: MacAddress = associationInfo.deviceMacAddress!!
                }

                override fun onFailure(errorMessage: CharSequence?) {
                    // Handle the failure.
                }
            }
        )

    }

//    @SuppressLint("MissingPermission")
//    override fun onActivityResult(
//        requestCode: Int,
//        resultCode: Int,
//        data: Intent?,
//        caller: ComponentCaller
//    ) {
//        when (requestCode) {
//            SELECT_DEVICE_REQUEST_CODE -> when (resultCode) {
//                RESULT_OK -> {
//                    // The user chose to pair the app with a Bluetooth device.
//                    val deviceToPair: BluetoothDevice? =
//                        data?.getParcelableExtra(CompanionDeviceManager.EXTRA_DEVICE,
//                            BluetoothDevice::class.java)
//                    deviceToPair?.let { device ->
//                        if (ActivityCompat.checkSelfPermission(
//                                this,
//                                Manifest.permission.BLUETOOTH_CONNECT
//                            ) != PackageManager.PERMISSION_GRANTED
//                        ) {
//                            // TODO: Consider calling
//                            //    ActivityCompat#requestPermissions
//                            // here to request the missing permissions, and then overriding
//                            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
//                            //                                          int[] grantResults)
//                            // to handle the case where the user grants the permission. See the documentation
//                            // for ActivityCompat#requestPermissions for more details.
//                            return
//                        }
//                        device.createBond()
//                        // Maintain continuous interaction with a paired device.
//                    }
//                }
//            }
//
//            else -> super.onActivityResult(requestCode, resultCode, data)
//        }
//    }
}

@PreviewScreenSizes
@Composable
fun BottleApp() {
    var currentDestination by rememberSaveable { mutableStateOf(AppDestinations.HOME) }

    NavigationSuiteScaffold(
        navigationSuiteItems = {
            AppDestinations.entries.forEach {
                item(
                    icon = {
                        Icon(
                            painterResource(it.icon),
                            contentDescription = it.label
                        )
                    },
                    label = { Text(it.label) },
                    selected = it == currentDestination,
                    onClick = { currentDestination = it }
                )
            }
        }
    ) {
        Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
            DeviceListPage(
                modifier = Modifier.padding(innerPadding)
            )
        }
    }
}

enum class AppDestinations(
    val label: String,
    val icon: Int,
) {
    HOME("Home", R.drawable.ic_home),
    FAVORITES("Favorites", R.drawable.ic_favorite),
    PROFILE("Profile", R.drawable.ic_account_box),
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    BottleTheme {
        Greeting("Android")
    }
}