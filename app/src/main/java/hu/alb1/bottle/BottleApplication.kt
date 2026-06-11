@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.app.Application
import android.bluetooth.BluetoothManager
import androidx.core.content.getSystemService
import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import dagger.hilt.android.HiltAndroidApp
import hu.alb1.bottle.data.AppDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlin.time.ExperimentalTime

@HiltAndroidApp
class BottleApplication : Application() {
    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val appViewModel = AppViewModel(applicationScope, this)
    lateinit var bleScanner: BleScanner
    lateinit var syncService: SyncService
    lateinit var db: AppDatabase

    override fun onCreate() {
        super.onCreate()
        bleScanner = BleScanner(getSystemService<BluetoothManager>()!!)
        syncService = SyncService(appViewModel, bleScanner)
        applicationScope.launch { syncService.loop() }
        db = Room.databaseBuilder(
            applicationContext,
            AppDatabase::class.java, "bottle"
        ).build()
    }
}


@Entity
data class User(
    @PrimaryKey val uid: Int,
    @ColumnInfo(name = "first_name") val firstName: String?,
    @ColumnInfo(name = "last_name") val lastName: String?
)

@Dao
interface UserDao {
    @Query("SELECT * FROM user")
    fun getAll(): List<User>

    @Query("SELECT * FROM user WHERE uid IN (:userIds)")
    fun loadAllByIds(userIds: IntArray): List<User>

    @Query("SELECT * FROM user WHERE first_name LIKE :first AND " +
            "last_name LIKE :last LIMIT 1")
    fun findByName(first: String, last: String): User

    @Insert
    fun insertAll(vararg users: User)

    @Delete
    fun delete(user: User)
}