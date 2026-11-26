# WorkManager makes its database by calling the generated class's empty
# constructor through reflection, which the shrinking cannot see, so it
# removed it and the app crashed on start.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
