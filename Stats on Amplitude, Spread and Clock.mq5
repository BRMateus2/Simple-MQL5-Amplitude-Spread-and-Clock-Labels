/*
Copyright (C) 2021 Mateus Matucuma Teixeira

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/
#ifndef SASC_H
#define SASC_H
//+------------------------------------------------------------------+
//|                         Stats on Amplitude, Spread and Clock.mq5 |
//|                         Copyright 2021, Mateus Matucuma Teixeira |
//|                                            mateusmtoss@gmail.com |
//| GNU General Public License version 2 - GPL-2.0                   |
//| https://opensource.org/licenses/gpl-2.0.php                      |
//+------------------------------------------------------------------+
// https://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels/
//---- Main Properties
#property copyright "2021, Mateus Matucuma Teixeira"
#property link "https://github.com/BRMateus2/"
#property description "This simple indicator is just a statistical label showing Last and Current Candle Amplitude (MinMax), Last and Current Day Amplitude, Current Tick Amplitude and Time Remaining for next Candle.\n"
#property description "It also shows Server Time (Market Watch) and Local PC Time so you can focus more on the graph and adapt to market hours.\n"
#property description "You can get the source code at \n\thttps://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels/"
#property version "1.04"
#property strict
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0
//---- Definitions
#define ErrorPrint(Dp_error) Print("ERROR: " + Dp_error + " at \"" + __FUNCTION__ + ":" + IntegerToString(__LINE__) + "\", last internal error: " + IntegerToString(GetLastError()) + " (" + __FILE__ + ")"); ResetLastError(); DebugBreak(); // It should be noted that the GetLastError() function doesn't zero the _LastError variable. Usually the ResetLastError() function is called before calling a function, after which an error appearance is checked.
//#define INPUT const
#ifndef INPUT
#define INPUT input
#endif
//---- Indicator Definitions
const string short_name = "StatsAndClock";
//---- Input Parameters
//---- "Label Settings"
input group "Label Settings"
INPUT color text_color = clrYellow; // Text Color
INPUT ENUM_BASE_CORNER corner = CORNER_RIGHT_UPPER; // Text Corner
INPUT long font_size = 12; // Font Size
INPUT string font_name = "DejaVu Sans Mono"; // Font Name (system naming)
INPUT long distance_x = 0; // X Distance or Horizontal Position Offset
INPUT long distance_y = 0; // Y Distance or Vertical Position Offset
INPUT long spacing_y = 3; // Vertical gap between objects
//---- "Statistics"
input group "Statistics"
INPUT bool show_stats = true; // Show Statistics line?
enum SFormat { // SFormat
    kFirst, // Format Ampl(xA/xB)/(yA/yB) Spr(z) mm:ss - Amplitude/Spread
    kSecond // Format Chg(dA/dB) W([m,M]) Spr(z) mm:ss - Chg/WeekRange/Spread
};
INPUT int week_range = 52; // How many weeks should the range contain? Normally 52 weeks
INPUT SFormat s_format = kFirst; // Amplitude and Spread Stats Format
//---- "Clock"
input group "Clock"
enum DateFormat {
    kTimeSeconds, // Format hh:mm:ss
    kTimeMinutes, // Format hh:mm
    kTimeDateSeconds, // Format YYYY.MM.DD hh:mm:ss
    kTimeDateMinutes, // Format YYYY.MM.DD hh:mm
};
INPUT DateFormat date_format = kTimeDateSeconds; // Date Format
INPUT bool show_offset = true; // Show UTC Timezone Offset?
INPUT bool show_dates_same_line = true; // Show both dates on the same line?
//---- "Server Clock"
input group "Server Clock"
INPUT bool use_server_date = true; // Use Server Date instead of Local/UTC Date?
//---- "Local Clock"
input group "Local Clock"
INPUT bool show_local = true; // Show Local Time Label?
INPUT bool show_local_as_utc = false; // Use UTC+0 / GMT Time instead of Local Timezone?
//---- Objects
const string obj_s = "AmplitudeAndSpread"; // Object Stats, used for naming
const string obj_cs = "ClockServer"; // Object Clock Server, used for naming
const string obj_cl = "ClockLocal"; // Object Clock Local, used for naming
//---- ChartRedraw() Timer optimization, calls once per second
datetime last = 0;
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Constructor or initialization function
// https://www.mql5.com/en/docs/basis/function/events
// https://www.mql5.com/en/articles/100
//+------------------------------------------------------------------+
int OnInit()
{
    last = TimeCurrent();
    IndicatorSetString(INDICATOR_SHORTNAME, short_name);
    ObjectDelete(ChartID(), obj_s);
    ObjectDelete(ChartID(), obj_cs);
    ObjectDelete(ChartID(), obj_cl);
    if(show_stats) {
        ObjectCreate(ChartID(), obj_s, OBJ_LABEL, ChartWindowFind(ChartID(), short_name), 0, 0.0);
        ObjectSetInteger(ChartID(), obj_s, OBJPROP_CORNER, corner);
        ObjectSetInteger(ChartID(), obj_s, OBJPROP_XDISTANCE, distance_x);
        ObjectSetInteger(ChartID(), obj_s, OBJPROP_YDISTANCE, distance_y);
        ObjectSetInteger(ChartID(), obj_s, OBJPROP_FONTSIZE, font_size);
        ObjectSetInteger(ChartID(), obj_s, OBJPROP_COLOR, text_color);
        ObjectSetString(ChartID(), obj_s, OBJPROP_FONT, font_name);
        ObjectSetString(ChartID(), obj_s, OBJPROP_TEXT, obj_s);
    }
    ObjectCreate(ChartID(), obj_cs, OBJ_LABEL, ChartWindowFind(ChartID(), short_name), 0, 0.0);
    ObjectSetInteger(ChartID(), obj_cs, OBJPROP_CORNER, corner);
    ObjectSetInteger(ChartID(), obj_cs, OBJPROP_XDISTANCE, distance_x);
    ObjectSetInteger(ChartID(), obj_cs, OBJPROP_YDISTANCE,  (
                         (show_stats ? ((font_size + spacing_y) + distance_y) : distance_y)
                     ));
    ObjectSetInteger(ChartID(), obj_cs, OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(ChartID(), obj_cs, OBJPROP_COLOR, text_color);
    ObjectSetString(ChartID(), obj_cs, OBJPROP_FONT, font_name);
    ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, obj_cs);
    if(show_local && !show_dates_same_line) {
        ObjectCreate(ChartID(), obj_cl, OBJ_LABEL, ChartWindowFind(ChartID(), short_name), 0, 0.0);
        ObjectSetInteger(ChartID(), obj_cl, OBJPROP_CORNER, corner);
        ObjectSetInteger(ChartID(), obj_cl, OBJPROP_XDISTANCE, distance_x);
        ObjectSetInteger(ChartID(), obj_cl, OBJPROP_YDISTANCE, (
                             (show_stats ? ((2 * (font_size + spacing_y)) + distance_y) : ((font_size + spacing_y) + distance_y))
                         ));
        ObjectSetInteger(ChartID(), obj_cl, OBJPROP_FONTSIZE, font_size);
        ObjectSetInteger(ChartID(), obj_cl, OBJPROP_COLOR, text_color);
        ObjectSetString(ChartID(), obj_cl, OBJPROP_FONT, font_name);
        ObjectSetString(ChartID(), obj_cl, OBJPROP_TEXT, obj_cl);
    }
    ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER;
    switch (corner) {
    case CORNER_LEFT_UPPER:
        anchor = ANCHOR_LEFT_UPPER;
        break;
    case CORNER_RIGHT_UPPER:
        anchor = ANCHOR_RIGHT_UPPER;
        break;
    case CORNER_LEFT_LOWER:
        anchor = ANCHOR_LEFT_LOWER;
        break;
    case CORNER_RIGHT_LOWER:
        anchor = ANCHOR_RIGHT_LOWER;
        break;
    }
    if(show_stats) {
        ObjectSetInteger(ChartID(), obj_s, OBJPROP_ANCHOR, anchor);
    }
    ObjectSetInteger(ChartID(), obj_cs, OBJPROP_ANCHOR, anchor);
    if(show_local && !show_dates_same_line) {
        ObjectSetInteger(ChartID(), obj_cl, OBJPROP_ANCHOR, anchor);
    }
    if(!EventSetMillisecondTimer(1000)) {
        ErrorPrint("!EventSetMillisecondTimer(1000) failure at subscribing to event timer");    // Create Timer Event in seconds (use EventSetMillisecondTimer for higher precision or HFT/High Frequency Trading)
        return(INIT_FAILED);
    }
    OnTimer(); // Initialize Clock Values
    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
// Destructor or Deinitialization function
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectDelete(ChartID(), obj_s);
    ObjectDelete(ChartID(), obj_cs);
    ObjectDelete(ChartID(), obj_cl);
    return;
}
//+------------------------------------------------------------------+
// Timer function
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!show_local && !show_offset) {
        ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)));
    } else if(!show_local && show_offset) {
        ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()));
    } else if(show_local && show_dates_same_line && (date_format == kTimeSeconds || date_format == kTimeDateSeconds)) {
        if(!show_local_as_utc && use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeToString(TimeLocal(), TIME_SECONDS));
        } else if(show_local_as_utc && use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeToString(TimeGMT(), TIME_SECONDS));
        } else if(!show_local_as_utc && !use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeToString(TimeLocal(), EnumToInt(date_format)));
        } else if(show_local_as_utc && !use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeToString(TimeGMT(), EnumToInt(date_format)));
        } else if(!show_local_as_utc && use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), TIME_SECONDS) + " " + TimeGMTOffset(TimeLocal()));
        } else if(show_local_as_utc && use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), TIME_SECONDS) + " " + TimeGMTOffset(TimeGMT()));
        } else if(!show_local_as_utc && !use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeLocal()));
        } else if(show_local_as_utc && !use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeGMT()));
        } else {
            ErrorPrint("untreated condition with show_local: \"" + (string) show_local + "\" " + "show_offset: \"" + (string) show_offset + "\" " + "show_dates_same_line: \"" + (string) show_dates_same_line + "\" " + "date_format: \"" + EnumToString(date_format) + "\" " + "show_local_as_utc: \"" + (string) show_local_as_utc + "\" " + "use_server_date: \"" + (string) use_server_date + "\" " + "\"");
        }
    } else if(show_local && show_dates_same_line && (date_format == kTimeMinutes || date_format == kTimeDateMinutes)) {
        if(!show_local_as_utc && use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeToString(TimeLocal(), TIME_MINUTES));
        } else if(show_local_as_utc && use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeToString(TimeGMT(), TIME_MINUTES));
        } else if(!show_local_as_utc && !use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeToString(TimeLocal(), EnumToInt(date_format)));
        } else if(show_local_as_utc && !use_server_date && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeToString(TimeGMT(), EnumToInt(date_format)));
        } else if(!show_local_as_utc && use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), TIME_MINUTES) + " " + TimeGMTOffset(TimeLocal()));
        } else if(show_local_as_utc && use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), TIME_MINUTES) + " " + TimeGMTOffset(TimeGMT()));
        } else if(!show_local_as_utc && !use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeLocal()));
        } else if(show_local_as_utc && !use_server_date && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeGMT()));
        } else {
            ErrorPrint("untreated condition with show_local: \"" + (string) show_local + "\" " + "show_offset: \"" + (string) show_offset + "\" " + "show_dates_same_line: \"" + (string) show_dates_same_line + "\" " + "date_format: \"" + EnumToString(date_format) + "\" " + "show_local_as_utc: \"" + (string) show_local_as_utc + "\" " + "use_server_date: \"" + (string) use_server_date + "\" " + "\"");
        }
    } else if(show_local && !show_dates_same_line) {
        if(!show_local_as_utc && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)));
            ObjectSetString(ChartID(), obj_cl, OBJPROP_TEXT, TimeToString(TimeLocal(), EnumToInt(date_format)));
        } else if(!show_local_as_utc && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()));
            ObjectSetString(ChartID(), obj_cl, OBJPROP_TEXT, TimeToString(TimeLocal(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeLocal()));
        } else if (show_local_as_utc && !show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)));
            ObjectSetString(ChartID(), obj_cl, OBJPROP_TEXT, TimeToString(TimeGMT(), EnumToInt(date_format)));
        } else if (show_local_as_utc && show_offset) {
            ObjectSetString(ChartID(), obj_cs, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeTradeServer()));
            ObjectSetString(ChartID(), obj_cl, OBJPROP_TEXT, TimeToString(TimeGMT(), EnumToInt(date_format)) + " " + TimeGMTOffset(TimeGMT()));
        } else {
            ErrorPrint("untreated condition with show_local: \"" + (string) show_local + "\" " + "show_offset: \"" + (string) show_offset + "\" " + "show_dates_same_line: \"" + (string) show_dates_same_line + "\" " + "date_format: \"" + EnumToString(date_format) + "\" " + "show_local_as_utc: \"" + (string) show_local_as_utc + "\" " + "use_server_date: \"" + (string) use_server_date + "\" " + "\"");
        }
    } else {
        ErrorPrint("untreated condition with show_local: \"" + (string) show_local + "\" " + "show_offset: \"" + (string) show_offset + "\" " + "show_dates_same_line: \"" + (string) show_dates_same_line + "\" " + "date_format: \"" + EnumToString(date_format) + "\" " + "show_local_as_utc: \"" + (string) show_local_as_utc + "\" " + "use_server_date: \"" + (string) use_server_date + "\" " + "\"");
    }
    if(last < TimeCurrent()) {
        last = TimeCurrent();
        ChartRedraw();
    }
    return;
}
//+------------------------------------------------------------------+
// Calculation function
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
    if(!show_stats || (rates_total <= 1)) { // No need to calculate if the data is less than the minimum operational period, or show_stats is false - it is returned as 0, because if we return rates_total, then the terminal interprets that the indicator has valid data
        return 0;
    }
    last = TimeCurrent();
    datetime m = ((time[rates_total - 1] + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent()) < 0) ? 0 : (time[rates_total - 1] + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent());
    datetime s = m % 60;
    m = (m - s) / 60;
    if(s_format == kFirst) {
        ObjectSetString(ChartID(), obj_s, OBJPROP_TEXT,
                        "Ampl(" + DoubleToString(high[rates_total - 2] - low[rates_total - 2], Digits()) + "/" + DoubleToString(high[rates_total - 1] - low[rates_total - 1], Digits()) + ")" +
                        "/D1(" + DoubleToString((iHigh(Symbol(), PERIOD_D1, 1) - iLow(Symbol(), PERIOD_D1, 1)), Digits()) + "/" + DoubleToString((iHigh(Symbol(), PERIOD_D1, 0) - iLow(Symbol(), PERIOD_D1, 0)), Digits()) + ")" +
                        " Spr(" + IntegerToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)) + (SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 10 ? "..." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 100 ? ".." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 1000 ? "." : "") + ") " + (m < 10 ? "0" : "") + IntegerToString((m < 0 ? 0 : m)) + ":" + (s < 10 ? "0" : "") + IntegerToString((s < 0 ? 0 : s))
                       );
    } else if(s_format == kSecond) {
        ObjectSetString(ChartID(), obj_s, OBJPROP_TEXT,
                        "Chg(" + DoubleToString((iClose(Symbol(), PERIOD_D1, 2) ? ((iClose(Symbol(), PERIOD_D1, 1) * 100.0 / iClose(Symbol(), PERIOD_D1, 2)) - 100.0) : 0.0), 2) + "%/" + /* Check for Division by Zero, skips calculation if true - unfortunately MQL5 does not follow IEEE 754 Standards, which enforces no error at "zero divide in", such case of 0.0/0.0 should have resulted in NaN and happens because of the platform asynchronous nature of loading different timeframes than the current */
                        DoubleToString((iClose(Symbol(), PERIOD_D1, 1) ? ((iClose(Symbol(), PERIOD_D1, 0) * 100.0 / iClose(Symbol(), PERIOD_D1, 1)) - 100.0) : 0.0), 2) + "%)" + /* Check for Division by Zero, skips calculation if true - unfortunately MQL5 does not follow IEEE 754 Standards, which enforces no error at "zero divide in", such case of 0.0/0.0 should have resulted in NaN and happens because of the platform asynchronous nature of loading different timeframes than the current */
                        " W" + IntegerToString(week_range) + "[" + DoubleToString(iLow(Symbol(), PERIOD_W1, iLowest(Symbol(), PERIOD_W1, MODE_LOW, week_range, 0)), Digits()) +
                        ", " + DoubleToString(iHigh(Symbol(), PERIOD_W1, iHighest(Symbol(), PERIOD_W1, MODE_HIGH, week_range, 0)), Digits()) + "]" +
                        " Spr(" + IntegerToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)) + (SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 10 ? "..." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 100 ? ".." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 1000 ? "." : "") + ") " + (m < 10 ? "0" : "") + IntegerToString((m < 0 ? 0 : m)) + ":" + (s < 10 ? "0" : "") + IntegerToString((s < 0 ? 0 : s))
                       );
    } else {
        ErrorPrint("not implemented");
    }
//ChartRedraw(); // Performance loss is HUGE on every Tick - also, after OnCalculate is returned (such event called only on a Tick, calculation), the platform itself executes a ChartRedraw() and processes the object queue - doing a ChartRedraw() here is just a waste of CPU cycles
    return rates_total; // Calculations are done and valid
}
//+------------------------------------------------------------------+
// TODO improve function to ignore 1s desync
// Time to Greenwich Mean Time (GMT) Offset formatted output
// string TimeGMTOffset(datetime t)
// Consistency with datetime TimeGMTOffset(void)
// This function returns a formatted string containing the timezone
// offset, for example, +02:00 for UTC +02:00.
// The precision of the returned value depends on how accurate the
// local computer is synchronized to a Network Time Protocol (NTP)
// server, also how accurate the server is in sync to a NTP server,
// and how accurate the local NTP server is in sync with
// server NTP server or related clock sync data.
// Can return wrong Server Offset information if the error is bigger
// than or equal to 1 second between the Server and Local.
//+------------------------------------------------------------------+
string TimeGMTOffset(long t = 0)
{
    string s;
    t = t - TimeGMT();
    if(t < 0) {
        s = "-" + IntegerToString((long) MathFloor(MathAbs(t) / 3600.0), 2, (char) '0') + ":" + IntegerToString((long) ((MathAbs(t) % 3600) / 60), 2, (char) '0');
    } else {
        s = "+" + IntegerToString((long) MathFloor(t / 3600.0), 2, (char) '0') + ":" + IntegerToString((long) ((MathAbs(t) % 3600) / 60), 2, (char) '0');
    }
    return s;
}
//+------------------------------------------------------------------+
// TODO
// Rounding method to-nearest as FE_TONEAREST = int fegetround(void)
// Also called half-up
// long round(long v, long i = 1)
// v = value to round
// i = interval of rounding, default 10
// returns rounded value as a long integer
// The method half-up adapted to a custom user-defined interval.
// It will always be biased upwards using a odd interval value
// because 5 rounded in 10 intervals equals to 10 as object count
// (in math notation) [0; 10[ equals to 10 elements
// but 4 rounded in 9 intervals equals to 9, as the object
// count [0; 9[ equals to 9 elements (9/2 has a up-bias for 4)
// this means that a odd interval will always have a single more
// round-ups than round-downs in a uniform-distribution rounding.
//+------------------------------------------------------------------+
long round(long v, long i = 10)
{
    if(modf(((double) v / (double) i)) >= 0.5) {
    } else {
    }
    return v;
}
//+------------------------------------------------------------------+
// TODO
// Extractor of Integral and Fractional Parts
// double modf(double x)
// x = value to decompose into parts
// iptr from C Standard Library is not allowed.
// C Standard Library documentation:
// https://en.cppreference.com/w/cpp/numeric/math/modf
// Decomposes given floating point value x into integral and
// fractional parts, each having the same type and sign as x.
// The integral part (in floating-point format) is stored in the
// object pointed to by iptr.
// To make iptr usable, we have to return a struct, not going to do this now.
//+------------------------------------------------------------------+
double modf(double x)
{
    double i = 0.0;
    if(x >= +0.0) {
        i = MathFloor(x);
    } else {
        i = MathCeil(x);
    }
    return (x - i);
}
//+------------------------------------------------------------------+
// Extra functions, utilities and conversion
//+------------------------------------------------------------------+
int EnumToInt(DateFormat e)
{
    if(e == kTimeSeconds) {
        return TIME_SECONDS;
    } else if(e == kTimeMinutes) {
        return TIME_MINUTES;
    } else if(e == kTimeDateSeconds) {
        return TIME_DATE | TIME_SECONDS;
    } else if(e == kTimeDateMinutes) {
        return TIME_DATE | TIME_MINUTES;
    }
    return -1;
}
//+------------------------------------------------------------------+
//| Header Guard #endif
//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
