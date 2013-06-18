/*
 * @(#)TimeZone.java	1.17 97/01/29
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

import java.io.Serializable;
import java.io.ObjectInputStream;

/**
 * <code>TimeZone</code> represents a time zone offset, and also figures out daylight
 * savings.
 *
 * <p>
 * Typically, you get a <code>TimeZone</code> using <code>getDefault</code>
 * which creates a <code>TimeZone</code> based on the time zone where the program
 * is running. For example, for a program running in Japan, <code>getDefault</code>
 * creates a <code>TimeZone</code> object based on Japanese Standard Time.
 *
 * <p>
 * You can also get a <code>TimeZone</code> using <code>getTimeZone</code> along
 * with a time zone ID. For instance, the time zone ID for the Pacific
 * Standard Time zone is "PST". So, you can get a PST <code>TimeZone</code> object
 * with:
 * <blockquote>
 * <pre>
 * TimeZone tz = TimeZone.getTimeZone("PST");
 * </pre>
 * </blockquote>
 * You can use <code>getAvailableIDs</code> method to iterate through
 * all the supported time zone IDs. You can then choose a
 * supported ID to get a favorite <code>TimeZone</code>.
 *
 * @see          Calendar
 * @see          GregorianCalendar
 * @see          SimpleTimeZone
 * @version      1.17 01/29/97
 * @author       Mark Davis, David Goldsmith, Chen-Lieh Huang
 */
abstract public class TimeZone implements Serializable, Cloneable {

    public TimeZone() {
	throw new NoSuchElementException();
    }

    /**
     * Gets the time zone offset, for current date, modified in case of
     * daylight savings. This is the offset to add *to* UTC to get local time.
     * @param era the era of the given date.
     * @param year the year in the given date.
     * @param month the month in the given date.
     * Month is 0-based. e.g., 0 for January.
     * @param day the day-in-month of the given date.
     * @param dayOfWeek the day-of-week of the given date.
     * @param milliseconds the millis in day.
     * @return the offset to add *to* GMT to get local time.
     */
    abstract public int getOffset(int era, int year, int month, int day,
                                  int dayOfWeek, int milliseconds);

    /**
     * Sets the base time zone offset to GMT.
     * This is the offset to add *to* UTC to get local time.
     * @param offsetMillis the given base time zone offset to GMT.
     */
    abstract public void setRawOffset(int offsetMillis);

    /**
     * Gets unmodified offset, NOT modified in case of daylight savings.
     * This is the offset to add *to* UTC to get local time.
     * @return the unmodified offset to add *to* UTC to get local time.
     */
    abstract public int getRawOffset();

    /**
     * Gets the ID of this time zone.
     * @return the ID of this time zone.
     */
    public String getID()
    {
	throw new NoSuchElementException();
    }

    /**
     * Sets the time zone ID. This does not change any other data in
     * the time zone object.
     * @param ID the new time zone ID.
     */
    public void setID(String ID)
    {
	throw new NoSuchElementException();
    }

    /**
     * Queries if this time zone uses Daylight Savings Time.
     * @return true if this time zone uses Daylight Savings Time,
     * false, otherwise.
     */
    abstract public boolean useDaylightTime();

    /**
     * Queries if the given date is in Daylight Savings Time in
     * this time zone.
     * @param date the given Date.
     * @return true if the given date is in Daylight Savings Time,
     * false, otherwise.
     */
    abstract public boolean inDaylightTime(Date date);

    /**
     * Gets the TimeZone for the given ID.
     * @param ID the given ID.
     * @return a TimeZone.
     */
    public static synchronized TimeZone getTimeZone(String ID)
    {
	throw new NoSuchElementException();
    }

    /**
     * Gets the available IDs according to the given time zone offset.
     * @param rawOffset the given time zone GMT offset.
     * @return an array of IDs, where the time zone for that ID has
     * the specified GMT offset. For example, {"Phoenix", "Denver"},
     * since both have GMT-07:00, but differ in daylight savings behavior.
     */
    public static synchronized String[] getAvailableIDs(int rawOffset) {
	throw new NoSuchElementException();
    }

    /**
     * Gets all the available IDs supported.
     * @return an array of IDs.
     */
    public static synchronized String[] getAvailableIDs() {
	throw new NoSuchElementException();
    }

    /**
     * Gets the default TimeZone for this host.
     * @return a default TimeZone.
     */
    public static synchronized TimeZone getDefault() {
	throw new NoSuchElementException();
    }

    /**
     * Sets time zone to using the given TimeZone.
     * @param zone the given time zone.
     */
    public static synchronized void setDefault(TimeZone zone)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Cloneable
     */
    public Object clone()
    {
	throw new NoSuchElementException();
    }

    private void readObject(ObjectInputStream s) {
	throw new NoSuchElementException();
    }
}
