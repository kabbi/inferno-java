/*
 * @(#)GregorianCalendar.java	1.20 97/03/09
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
 * <code>GregorianCalendar</code> is a concrete subclass of
 * <a href="java.util.Calendar.html"><code>Calendar</code></a>
 * and provides the standard calendar used by most of the world.
 *
 * <p>
 * The standard (Gregorian) calendar has 2 eras, BC and AD.
 *
 * <p>
 * This implementation handles a single discontinuity, which corresponds
 * by default to the date the Gregorian calendar was instituted (October 15,
 * 1582 in some countries, later in others). This cutover date may be changed
 * by the caller.
 *
 * <p>
 * Prior to the institution of the Gregorian calendar, New Year's Day was
 * March 25. To avoid confusion, this calendar always uses January 1. A manual
 * adjustment may be made if desired for dates that are prior to the Gregorian
 * changeover and which fall between January 1 and March 24.
 *
 * <p> 
 * <strong>Example:</strong>
 * <blockquote>
 * <pre>
 * 	// get the supported ids for GMT-08:00 (Pacific Standard Time)
 * String[] ids = TimeZone.getAvailableIDs(-8 * 60 * 60 * 1000);
 * 	// if no ids were returned, something is wrong. get out.
 * if (ids.length == 0)
 *     System.exit(0);
 *
 * 	// begin output
 * System.out.println("Current Time");
 *
 * 	// create a Pacific Standard Time time zone
 * SimpleTimeZone pdt = new SimpleTimeZone(-8 * 60 * 60 * 1000, ids[0]);
 *
 * 	// set up rules for daylight savings time
 * pdt.setStartRule(Calendar.APRIL, 1, Calendar.SUNDAY, 2 * 60 * 60 * 1000);
 * pdt.setEndRule(Calendar.OCTOBER, -1, Calendar.SUNDAY, 2 * 60 * 60 * 1000);
 *
 * 	// create a GregorianCalendar with the Pacific Daylight time zone
 *	// and the current date and time
 * Calendar calendar = new GregorianCalendar(pdt);
 * Date trialTime = new Date();
 * calendar.setTime(trialTime);
 *
 *	// print out a bunch of interesting things
 * System.out.println("ERA: " + calendar.get(Calendar.ERA));
 * System.out.println("YEAR: " + calendar.get(Calendar.YEAR));
 * System.out.println("MONTH: " + calendar.get(Calendar.MONTH));
 * System.out.println("WEEK_OF_YEAR: " + calendar.get(Calendar.WEEK_OF_YEAR));
 * System.out.println("WEEK_OF_MONTH: " + calendar.get(Calendar.WEEK_OF_MONTH));
 * System.out.println("DATE: " + calendar.get(Calendar.DATE));
 * System.out.println("DAY_OF_MONTH: " + calendar.get(Calendar.DAY_OF_MONTH));
 * System.out.println("DAY_OF_YEAR: " + calendar.get(Calendar.DAY_OF_YEAR));
 * System.out.println("DAY_OF_WEEK: " + calendar.get(Calendar.DAY_OF_WEEK));
 * System.out.println("DAY_OF_WEEK_IN_MONTH: "
 *                    + calendar.get(Calendar.DAY_OF_WEEK_IN_MONTH));
 * System.out.println("AM_PM: " + calendar.get(Calendar.AM_PM));
 * System.out.println("HOUR: " + calendar.get(Calendar.HOUR));
 * System.out.println("HOUR_OF_DAY: " + calendar.get(Calendar.HOUR_OF_DAY));
 * System.out.println("MINUTE: " + calendar.get(Calendar.MINUTE));
 * System.out.println("SECOND: " + calendar.get(Calendar.SECOND));
 * System.out.println("MILLISECOND: " + calendar.get(Calendar.MILLISECOND));
 * System.out.println("ZONE_OFFSET: "
 *                    + (calendar.get(Calendar.ZONE_OFFSET)/(60*60*1000)));
 * System.out.println("DST_OFFSET: "
 *                    + (calendar.get(Calendar.DST_OFFSET)/(60*60*1000)));

 * System.out.println("Current Time, with hour reset to 3");
 * calendar.clear(Calendar.HOUR_OF_DAY); // so doesn't override
 * calendar.set(Calendar.HOUR, 3);
 * System.out.println("ERA: " + calendar.get(Calendar.ERA));
 * System.out.println("YEAR: " + calendar.get(Calendar.YEAR));
 * System.out.println("MONTH: " + calendar.get(Calendar.MONTH));
 * System.out.println("WEEK_OF_YEAR: " + calendar.get(Calendar.WEEK_OF_YEAR));
 * System.out.println("WEEK_OF_MONTH: " + calendar.get(Calendar.WEEK_OF_MONTH));
 * System.out.println("DATE: " + calendar.get(Calendar.DATE));
 * System.out.println("DAY_OF_MONTH: " + calendar.get(Calendar.DAY_OF_MONTH));
 * System.out.println("DAY_OF_YEAR: " + calendar.get(Calendar.DAY_OF_YEAR));
 * System.out.println("DAY_OF_WEEK: " + calendar.get(Calendar.DAY_OF_WEEK));
 * System.out.println("DAY_OF_WEEK_IN_MONTH: "
 *                    + calendar.get(Calendar.DAY_OF_WEEK_IN_MONTH));
 * System.out.println("AM_PM: " + calendar.get(Calendar.AM_PM));
 * System.out.println("HOUR: " + calendar.get(Calendar.HOUR));
 * System.out.println("HOUR_OF_DAY: " + calendar.get(Calendar.HOUR_OF_DAY));
 * System.out.println("MINUTE: " + calendar.get(Calendar.MINUTE));
 * System.out.println("SECOND: " + calendar.get(Calendar.SECOND));
 * System.out.println("MILLISECOND: " + calendar.get(Calendar.MILLISECOND));
 * System.out.println("ZONE_OFFSET: "
 *        + (calendar.get(Calendar.ZONE_OFFSET)/(60*60*1000))); // in hours
 * System.out.println("DST_OFFSET: "
 *        + (calendar.get(Calendar.DST_OFFSET)/(60*60*1000))); // in hours
 * </pre>
 * </blockquote>
 *
 * @see          Calendar
 * @see          TimeZone
 * @version      1.20 03/09/97
 * @author       David Goldsmith, Mark Davis, Chen-Lieh Huang
 */
public class GregorianCalendar extends Calendar {

    // Internal notes:
    // This algorithm is based on the one presented on pp. 10-12 of
    // "Numerical Recipes in C", William H. Press, et. al., Cambridge
    // University Press 1988, ISBN 0-521-35465-X.

    /**
     * Useful constant for GregorianCalendar.
     */
    public static final int BC = 0;
    /**
     * Useful constant for GregorianCalendar.
     */
    public static final int AD = 1;

    // Note that the Julian date used here is not a true Julian date, since
    // it is measured from midnight, not noon.

    private static final long julianDayOffset = 2440588;
    private static final int millisPerDay = 24 * 60 * 60 * 1000;
    private static final int numDays[]
    = {0,31,59,90,120,151,181,212,243,273,304,334}; // 0-based, for day-in-year
    private static final int leapNumDays[]
    = {0,31,60,91,121,152,182,213,244,274,305,335}; // 0-based, for day-in-year
    private static final int maxDaysInMonth[]
    = {31,28,31,30,31,30,31,31,30,31,30,31}; // 0-based

    // This is measured from the standard epoch, not in Julian Days.
    // Default is 00:00:00 local time, October 15, 1582.
    private long gregorianCutover = -12219292800000L;

    /**
     * Converts time as milliseconds to Julian date.
     * @param millis the given milliseconds.
     * @return the Julian date number.
     */
    private static final long millisToJulianDay(long millis)
    {
	throw new NoSuchElementException();
    }

    /**
     * Converts Julian date to time as milliseconds.
     * @param julian the given Julian date number.
     * @return time as milliseconds.
     */
    private static final long julianDayToMillis(long julian)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a default GregorianCalendar using the current time
     * in the default time zone with the default locale.
     */
    public GregorianCalendar()
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a GregorianCalendar based on the current time
     * in the given time zone with the default locale.
     * @param zone the given time zone.
     */
    public GregorianCalendar(TimeZone zone)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a GregorianCalendar based on the current time
     * in the default time zone with the given locale.
     * @param aLocale the given locale.
     */
    public GregorianCalendar(Locale aLocale)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a GregorianCalendar based on the current time
     * in the given time zone with the given locale.
     * @param zone the given time zone.
     * @param aLocale the given locale.
     */
    public GregorianCalendar(TimeZone zone, Locale aLocale)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a GregorianCalendar with the given date set
     * in the default time zone with the default locale.
     * @param year the value used to set the YEAR time field in the calendar.
     * @param month the value used to set the MONTH time field in the calendar.
     * Month value is 0-based. e.g., 0 for January.
     * @param date the value used to set the DATE time field in the calendar.
     */
    public GregorianCalendar(int year, int month, int date)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a GregorianCalendar with the given date
     * and time set for the default time zone with the default locale.
     * @param year the value used to set the YEAR time field in the calendar.
     * @param month the value used to set the MONTH time field in the calendar.
     * Month value is 0-based. e.g., 0 for January.
     * @param date the value used to set the DATE time field in the calendar.
     * @param hour the value used to set the HOUR_OF_DAY time field
     * in the calendar.
     * @param minute the value used to set the MINUTE time field
     * in the calendar.
     */
    public GregorianCalendar(int year, int month, int date, int hour,
                             int minute)
    {
	throw new NoSuchElementException();
    }

    /**
     * Constructs a GregorianCalendar with the given date
     * and time set for the default time zone with the default locale.
     * @param year the value used to set the YEAR time field in the calendar.
     * @param month the value used to set the MONTH time field in the calendar.
     * Month value is 0-based. e.g., 0 for January.
     * @param date the value used to set the DATE time field in the calendar.
     * @param hour the value used to set the HOUR_OF_DAY time field
     * in the calendar.
     * @param minute the value used to set the MINUTE time field
     * in the calendar.
     * @param second the value used to set the SECOND time field
     * in the calendar.
     */
    public GregorianCalendar(int year, int month, int date, int hour,
                             int minute, int second)
    {
	throw new NoSuchElementException();
    }

    /**
     * Sets the GregorianCalendar change date. This is the point when the
     * switch from Julian dates to Gregorian dates occurred. Default is
     * 00:00:00 local time, October 15, 1582. Previous to this time and date
     * will be Julian dates.
     *
     * @param date the given Gregorian cutover date.
     */
    public void setGregorianChange(Date date)
    {
	throw new NoSuchElementException();
    }

    /**
     * Gets the Gregorian Calendar change date.  This is the point when the
     * switch from Julian dates to Gregorian dates occurred. Default is
     * 00:00:00 local time, October 15, 1582. Previous to
     * this time and date will be Julian dates.
     * @return the Gregorian cutover time for this calendar.
     */
    public final Date getGregorianChange()
    {
	throw new NoSuchElementException();
    }

    // Converts the time field list to the time as milliseconds.
    private final void timeToFields(long theTime)
    {
	throw new NoSuchElementException();
    }


    /**
     * @param date day-of-year or day-of-month. Month is zero based.
     * @param day day-of-week for date. Zero based.
     * @param firstDatesDay the day-of-week for the first day of the year
     * or month.
     * @param firstDay the first day of the week for the calendar.
     * e.g. Sunday for US.
     * @param minimalDaysInFirstWeek the minimal number of days in the
     * week to qualify as the first week; otherwise partial week belongs
     * to last (year/month).
     * <note> weekCount is the number of weeks in the (year/month) for the
     * date. If zero, belongs to last (year/month). You MUST add the date to
     * the last day of the previous (year/month), and call this method again!
     * @return week number, one-based.
     */
    private static int weekNumber(int date, int day, int firstDatesDay,
                                  int firstDay, int minimalDaysInFirstWeek)
    {
	throw new NoSuchElementException();
    }


    // XXX Currently this method has a bug, and it is not being used.
    private static int dateFrom(int weekNumber, int day, int firstDatesDay,
                                int firstDay, int minimalDaysInFirstWeek)
    {
	throw new NoSuchElementException();
    }


    /**
     * Determines if the given year is a leap year. Returns true if the
     * given year is a leap year.
     * @param year the given year.
     * @return true if the given year is a leap year; false otherwise.
     */
    public boolean isLeapYear(int year)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Calendar
     * Converts UTC as milliseconds to time field values.
     */
    protected void computeFields()
    {
	throw new NoSuchElementException();
    }

    /**
     * Validates the values of the set time fields.
     */
    private boolean validateFields()
    {
	throw new NoSuchElementException();
    }

    /**
     * Validates the value of the given time field.
     */
    private boolean boundsCheck(int value, int field)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Calendar
     * Converts time field values to UTC as milliseconds.
     * @exception IllegalArgumentException if an unknown field is given.
     */
    protected void computeTime()
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

    /**
     * Override hashCode.
     * Generates the hash code for the GregorianCalendar object
     */
    public synchronized int hashCode()
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Calendar
     * Compares the time field records.
     * Equivalent to comparing result of conversion to UTC.
     * Please see Calendar.equals for descriptions on parameters and
     * the return value.
     */
    public boolean equals(Object obj)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Calendar
     * Compares the time field records.
     * Equivalent to comparing result of conversion to UTC.
     * Please see Calendar.before for descriptions on parameters and
     * the return value.
     */
    public boolean before(Object when)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Calendar
     * Compares the time field records.
     * Equivalent to comparing result of conversion to UTC.
     * Please see Calendar.after for descriptions on parameters and
     * the return value.
     */
    public boolean after(Object when)
    {
	throw new NoSuchElementException();
    }

    /**
     * Overrides Calendar
     * Date Arithmetic function.
     * Adds the specified (signed) amount of time to the given time field,
     * based on the calendar's rules.
     * @param field the time field.
     * @param amount the amount of date or time to be added to the field.
     * @exception IllegalArgumentException if an unknown field is given.
     */
    public void add(int field, int amount)
    {
	throw new NoSuchElementException();
    }


    /**
     * Overrides Calendar
     * Time Field Rolling function.
     * Rolls (up/down) a single unit of time on the given time field.
     * @param field the time field.
     * @param up Indicates if rolling up or rolling down the field value.
     * @exception IllegalArgumentException if an unknown field value is given.
     */
    public void roll(int field, boolean up)
    {
	throw new NoSuchElementException();
    }


    // Roll the time field value down by 1.
    private void rollDown(int field)
    {
	throw new NoSuchElementException();
    }


    /**
     * <pre>
     * Field names Minimum Greatest Minimum Least Maximum Maximum
     * ----------- ------- ---------------- ------------- -------
     * ERA 0 0 1 1
     * YEAR 1 1 5,000,000 5,000,000
     * MONTH 0 0 11 11
     * WEEK_OF_YEAR 1 1 53 54
     * WEEK_OF_MONTH 1 1 4 6
     * DAY_OF_MONTH 1 1 28 31
     * DAY_OF_YEAR 1 1 365 366
     * DAY_OF_WEEK 1 1 7 7
     * DAY_OF_WEEK_IN_MONTH -1 -1 4 6
     * AM_PM 0 0 1 1
     * HOUR 0 0 11 12
     * HOUR_OF_DAY 0 0 23 23
     * MINUTE 0 0 59 59
     * SECOND 0 0 59 59
     * MILLISECOND 0 0 999 999
     * ZONE_OFFSET -12*60*60*1000 -12*60*60*1000 12*60*60*1000 12*60*60*1000
     * DST_OFFSET 0 0 1*60*60*1000 1*60*60*1000
     * </pre>
     */
    private static final int MinValues[]
    = {0,1,0,1,1,1,1,1,-1,0,0,0,0,0,0,-12*60*60*1000,0};
    private static final int GreatestMinValues[]
    = {0,1,0,1,1,1,1,1,-1,0,0,0,0,0,0,-12*60*60*1000,0};// same as MinValues
    private static final int LeastMaxValues[]
    = {1,5000000,11,53,4,28,365,7,4,1,11,23,59,59,999,
       12*60*60*1000,1*60*60*1000};
    private static final int MaxValues[]
    = {1,5000000,11,54,6,31,366,7,6,1,12,23,59,59,999,
       12*60*60*1000,1*60*60*1000};

    /**
     * Returns minimum value for the given field.
     * e.g. for Gregorian DAY_OF_MONTH, 1
     * Please see Calendar.getMinimum for descriptions on parameters and
     * the return value.
     */
    public int getMinimum(int field)
    {
	throw new NoSuchElementException();
    }

    /**
     * Returns maximum value for the given field.
     * e.g. for Gregorian DAY_OF_MONTH, 31
     * Please see Calendar.getMaximum for descriptions on parameters and
     * the return value.
     */
    public int getMaximum(int field)
    {
	throw new NoSuchElementException();
    }

    /**
     * Returns highest minimum value for the given field if varies.
     * Otherwise same as getMinimum(). For Gregorian, no difference.
     * Please see Calendar.getGreatestMinimum for descriptions on parameters
     * and the return value.
     */
    public int getGreatestMinimum(int field)
    {
	throw new NoSuchElementException();
    }

    /**
     * Returns lowest maximum value for the given field if varies.
     * Otherwise same as getMaximum(). For Gregorian DAY_OF_MONTH, 28
     * Please see Calendar.getLeastMaximum for descriptions on parameters and
     * the return value.
     */
    public int getLeastMaximum(int field)
    {
	throw new NoSuchElementException();
    }

    private void readObject(ObjectInputStream s) {
	throw new NoSuchElementException();
    }
}
