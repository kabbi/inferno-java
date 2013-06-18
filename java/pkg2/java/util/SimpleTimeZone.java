/*
 * @(#)SimpleTimeZone.java	1.12 97/03/05
 *
 * (C) Copyright Taligent, Inc. 1996 - All Rights Reserved
 * (C) Copyright IBM Corp. 1996 - All Rights Reserved
 *
 * Portions copyright (c) 1996 Sun Microsystems, Inc. All Rights Reserved.
 *
 *   The original version of this source code and documentation is copyrighted
 * and owned by Taligent, Inc., a wholly-owned subsidiary of IBM. These
 * materials are provided under terms of a License Agreement between Taligent
 * and Sun. This technology is protected by multiple US and International
 * patents. This notice and attribution to Taligent may not be removed.
 *   Taligent is a registered trademark of Taligent, Inc.
 *
 * Permission to use, copy, modify, and distribute this software
 * and its documentation for NON-COMMERCIAL purposes and without
 * fee is hereby granted provided that this copyright notice
 * appears in all copies. Please refer to the file "copyright.html"
 * for further important copyright and licensing information.
 *
 * SUN MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE SUITABILITY OF
 * THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE, OR NON-INFRINGEMENT. SUN SHALL NOT BE LIABLE FOR
 * ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR
 * DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.
 *
 */

package java.util;

import java.io.ObjectInputStream;

/**
 * <code>SimpleTimeZone</code> is a concrete subclass of <code>TimeZone</code>
 * that represents a time zone for use with a Gregorian
 * calendar. This simple class does not handle historical
 * changes, and has limited rules.
 *
 * <P>
 * Use a negative value for <code>dayOfWeekInMonth</code> to indicate that
 * <code>SimpleTimeZone</code> should count from the end of the month backwards.
 * For example, Daylight Savings Time ends at the last
 * (dayOfWeekInMonth = -1) Sunday in October, at 2 AM in standard time.
 *
 * @see          Calendar
 * @see          GregorianCalendar
 * @see          TimeZone
 * @version      1.12 03/05/97
 * @author       David Goldsmith, Mark Davis, Chen-Lieh Huang
 */
public class SimpleTimeZone extends TimeZone {
    /**
     * Constructs a SimpleTimeZone with the given base time zone offset
     * from GMT and time zone ID. Timezone IDs can be obtained from
     * TimeZone.getAvailableIDs. Normally you should use TimeZone.getDefault
     * to construct a TimeZone.
     * @param rawOffset the given base time zone offset to GMT.
     * @param ID the time zone ID which is obtained from
     * TimeZone.getAvailableIDs.
     */
    public SimpleTimeZone(int rawOffset, String ID)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a SimpleTimeZone with the given base time zone offset
     * from GMT, time zone ID, time to start and end the daylight time.
     * Timezone IDs can be obtained from TimeZone.getAvailableIDs.
     * Normally you should use TimeZone.getDefault to create a TimeZone.
     * For a time zone that does not use daylight saving time, do not
     * use this constructor; instead you should use
     * SimpleTimeZone(rawOffset, ID).
     * @param rawOffset the given base time zone offset to GMT.
     * @param ID the time zone ID which is obtained from
     * TimeZone.getAvailableIDs.
     * @param startMonth the daylight savings starting month. Month is 0-based.
     * eg, 0 for January.
     * @param startDayOfWeekInMonth the daylight savings starting
     * day-of-week-in-month. Please see the member description for an example.
     * @param startDayOfWeek the daylight savings starting day-of-week.
     * Please see the member description for an example.
     * @param startTime the daylight savings starting time. Please see the
     * member description for an example.
     * @param endMonth the daylight savings ending month. Month is 0-based.
     * eg, 0 for January.
     * @param endDayOfWeekInMonth the daylight savings ending
     * day-of-week-in-month. Please see the member description for an example.
     * @param endDayOfWeek the daylight savings ending day-of-week. Please see
     * the member description for an example.
     * @param endTime the daylight savings ending time. Please see the member
     * description for an example.
     */
    public SimpleTimeZone(int rawOffset, String ID, int startMonth,
    int startDayOfWeekInMonth, int startDayOfWeek, int startTime,
    int endMonth, int endDayOfWeekInMonth, int endDayOfWeek, int endTime)
    {
	throw new NoSuchElementException();
    }

    /**
     * Sets the daylight savings starting year.
     * @param year the daylight savings starting year.
     */
    public void setStartYear(int year)
    {
	throw new NoSuchElementException();
    }

    /**
     * Sets the daylight savings starting rule. For example, Daylight Savings
     * Time starts at the first Sunday in April, at 2 AM in standard time.
     * Therefore, you can set the start rule by calling:
     * setStartRule(TimeFields.APRIL, 1, TimeFields.SUNDAY, 2*60*60*1000);
     * @param month the daylight savings starting month. Month is 0-based.
     * eg, 0 for January.
     * @param dayOfWeekInMonth the daylight savings starting
     * day-of-week-in-month. Please see the member description for an example.
     * @param dayOfWeek the daylight savings starting day-of-week. Please see
     * the member description for an example.
     * @param time the daylight savings starting time. Please see the member
     * description for an example.
     */
    public void setStartRule(int month, int dayOfWeekInMonth, int dayOfWeek,
                             int time)
    {
	throw new NoSuchElementException();
    }

    /**
     * Sets the daylight savings ending rule. For example, Daylight Savings
     * Time ends at the last (-1) Sunday in October, at 2 AM in standard time.
     * Therefore, you can set the end rule by calling:
     * setEndRule(TimeFields.OCTOBER, -1, TimeFields.SUNDAY, 2*60*60*1000);
     * @param month the daylight savings ending month. Month is 0-based.
     * eg, 0 for January.
     * @param dayOfWeekInMonth the daylight savings ending
     * day-of-week-in-month. Please see the member description for an example.
     * @param dayOfWeek the daylight savings ending day-of-week. Please see
     * the member description for an example.
     * @param time the daylight savings ending time. Please see the member
     * description for an example.
     */
    public void setEndRule(int month, int dayOfWeekInMonth, int dayOfWeek,
                           int time)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides TimeZone
     * Gets offset, for current date, modified in case of daylight savings.
     * This is the offset to add *to* UTC to get local time.
     * Please see TimeZone.getOffset for descriptions on parameters.
     */
    public int getOffset(int era, int year, int month, int day, int dayOfWeek,
                         int millis)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides TimeZone
     * Gets the GMT offset for this time zone.
     */
    public int getRawOffset()
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides TimeZone
     * Sets the base time zone offset to GMT.
     * This is the offset to add *to* UTC to get local time.
     * Please see TimeZone.setRawOffset for descriptions on the parameter.
     */
    public void setRawOffset(int offsetMillis)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides TimeZone
     * Queries if this time zone uses Daylight Savings Time.
     */
    public boolean useDaylightTime()
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides TimeZone
     * Queries if the given date is in Daylight Savings Time.
     */
    public boolean inDaylightTime(Date date) {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Cloneable
     */
    public Object clone()
    {
	throw new NoSuchElementException();
    }

    /**
     * Override hashCode.
     * Generates the hash code for the SimpleDateFormat object
     */
    public synchronized int hashCode()
    {
	throw new NoSuchElementException();
    }

    /**
     * Compares the equality of two SimpleTimeZone objects.
     * @param obj the SimpleTimeZone object to be compared with.
     * @return true if the given obj is the same as this SimpleTimeZone
     * object; false otherwise.
     */
    public boolean equals(Object obj)
    {
	throw new NoSuchElementException(); 
    }

    // =======================privates===============================

    private int startMonth, startDay, startDayOfWeek, startTime;
    private int endMonth, endDay, endDayOfWeek, endTime;
    private int startYear;
    private int rawOffset;
    private boolean useDaylight=false; // indicate if this time zone uses DST
    private static final int millisPerHour = 60*60*1000;
    // WARNING: assumes that no rule is measured from the end of February,
    // since we don't handle leap years. Could handle assuming always
    // Gregorian, since we know they didn't have daylight time when
    // Gregorian calendar started.
    private final byte monthLength[] = {31,28,31,30,31,30,31,31,30,31,30,31};

    private void readObject(ObjectInputStream s) {
	throw new NoSuchElementException();
    }
}
