/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.automotive.companion

import android.content.ContentResolver
import android.graphics.Color
import android.provider.CalendarContract.Calendars

private val calendarColumnsToFetch = arrayOf(
  Calendars._ID,
  Calendars.CALENDAR_DISPLAY_NAME,
  Calendars.CALENDAR_COLOR,
  Calendars.ACCOUNT_NAME
)

/** Provides a getter to fetch calendar view items  */
internal class CalendarViewItemData(private val contentResolver: ContentResolver) {
  /** Returns a list of calendars with their IDs  */
  fun fetchCalendarViewItems(): List<CalendarViewItem> {
    val calendarViewItems = mutableListOf<CalendarViewItem>()

    contentResolver.query(Calendars.CONTENT_URI, calendarColumnsToFetch, null, null, null)
      .use { cursor ->
        if (cursor == null || cursor.count <= 0) {
          return@fetchCalendarViewItems listOf()
        }

        while (cursor.moveToNext()) {
          val id = cursor.getLong(cursor.getColumnIndex(Calendars._ID))
          val title = cursor.getString(cursor.getColumnIndex(Calendars.CALENDAR_DISPLAY_NAME))

          val color = if (!cursor.isNull(cursor.getColumnIndex(Calendars.CALENDAR_COLOR))) {
            Color.valueOf(cursor.getInt(cursor.getColumnIndex(Calendars.CALENDAR_COLOR)))
          } else {
            null
          }

          val account = cursor.getString(cursor.getColumnIndex(Calendars.ACCOUNT_NAME))
          calendarViewItems.add(CalendarViewItem(id.toString(), title, color, account))
        }
      }

    return calendarViewItems
  }
}
