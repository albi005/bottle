package hu.alb1.bottle.data

import androidx.room.Database
import androidx.room.RoomDatabase
import hu.alb1.bottle.User

@Database(entities = [User::class], version = 1)
abstract class AppDatabase : RoomDatabase() {
}
