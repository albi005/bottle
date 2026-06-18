package hu.alb1.bottle.data

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.paging.PagingSource
import hu.alb1.bottle.proto.CapEnumTofTriggerType

@Database(entities = [User::class, TofLogEntry::class], version = 2)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun tofLogEntryDao(): TofLogEntryDao
}

class Converters {
    @TypeConverter
    fun fromTriggerType(value: CapEnumTofTriggerType): Int = value.value

    @TypeConverter
    fun toTriggerType(value: Int): CapEnumTofTriggerType =
        CapEnumTofTriggerType.fromValue(value) ?: CapEnumTofTriggerType.TYPE_REQUEST
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

@Entity(
    tableName = "tof_log",
    indices = [Index(value = ["timestamp"])]
)
data class TofLogEntry(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    @ColumnInfo(name = "timestamp") val timestamp: Long,
    @ColumnInfo(name = "trigger_type") val triggerType: CapEnumTofTriggerType,
    @ColumnInfo(name = "distance_mm") val distanceInMillimeter: Int,
    @ColumnInfo(name = "kcps") val kcps: Int,
    @ColumnInfo(name = "uv_led_temp_ohm") val uvLedTempInOhm: Float,
)

@Dao
interface TofLogEntryDao {
    @Query("SELECT * FROM tof_log ORDER BY timestamp ASC")
    suspend fun getAll(): List<TofLogEntry>

    @Query("SELECT MAX(timestamp) FROM tof_log")
    suspend fun getLatestTimestamp(): Long?

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(vararg entries: TofLogEntry)

    @Query("SELECT * FROM tof_log ORDER BY timestamp DESC")
    fun getAllPaged(): PagingSource<Int, TofLogEntry>
}
