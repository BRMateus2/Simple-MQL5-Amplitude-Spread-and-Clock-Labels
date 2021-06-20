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
#property version "1.05"
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
const string iName = "StatsAndClock";
//---- Input Parameters
//---- "Label Settings"
input group "Label Settings"
INPUT color lColor = clrYellow; // Text Color
INPUT ENUM_BASE_CORNER lCorner = CORNER_RIGHT_UPPER; // Text Corner
INPUT long lFontSize = 12; // Font Size
INPUT string lFontName = "DejaVu Sans Mono"; // Font Name (system naming)
INPUT long oDistX = 0; // X Distance or Horizontal Position Offset
INPUT long oDistY = 0; // Y Distance or Vertical Position Offset
INPUT long oSpacingY = 3; // Vertical gap between objects
//---- "Statistics"
input group "Statistics"
INPUT bool oStatsShow = true; // Show Statistics line?
enum SFormat { // SFormat
    kFirst, // Format Ampl(xA/xB)/(yA/yB) Spr(z) mm:ss - Amplitude/Spread
    kSecond // Format Chg(dA/dB) W([m,M]) Spr(z) mm:ss - Chg/WeekRange/Spread
};
INPUT int weekRange = 52; // How many weeks should the range contain? Normally 52 weeks
INPUT SFormat sFormat = kFirst; // Amplitude and Spread Stats Format
//---- "Clock"
input group "Clock"
enum DateFormat {
    kTimeSeconds, // Format hh:mm:ss
    kTimeMinutes, // Format hh:mm
    kTimeDateSeconds, // Format YYYY.MM.DD hh:mm:ss
    kTimeDateMinutes, // Format YYYY.MM.DD hh:mm
};
INPUT DateFormat dFormat = kTimeDateSeconds; // Date Format
INPUT bool dShowOffset = true; // Show UTC Timezone Offset?
INPUT bool dShowSameLine = true; // Show both dates on the same line?
//---- "Server Clock"
input group "Server Clock"
INPUT bool dUseServer = true; // Use Server Date instead of Local/UTC Date?
//---- "Local Clock"
input group "Local Clock"
INPUT bool dShowLocal = true; // Show Local Time Label?
INPUT bool dShowLocalAsUTC = false; // Use UTC+0 / GMT Time instead of Local Timezone?
//---- Objects
const string oStats = "AmplitudeAndSpread"; // Object Stats, used for naming
const string oCS = "ClockServer"; // Object Clock Server, used for naming
const string oCL = "ClockLocal"; // Object Clock Local, used for naming
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
    last = TimeGMT();
    IndicatorSetString(INDICATOR_SHORTNAME, iName);
    ObjectDelete(ChartID(), oStats);
    ObjectDelete(ChartID(), oCS);
    ObjectDelete(ChartID(), oCL);
    if(oStatsShow) {
        ObjectCreate(ChartID(), oStats, OBJ_LABEL, ChartWindowFind(ChartID(), iName), 0, 0.0);
        ObjectSetInteger(ChartID(), oStats, OBJPROP_CORNER, lCorner);
        ObjectSetInteger(ChartID(), oStats, OBJPROP_XDISTANCE, oDistX);
        ObjectSetInteger(ChartID(), oStats, OBJPROP_YDISTANCE, oDistY);
        ObjectSetInteger(ChartID(), oStats, OBJPROP_FONTSIZE, lFontSize);
        ObjectSetInteger(ChartID(), oStats, OBJPROP_COLOR, lColor);
        ObjectSetString(ChartID(), oStats, OBJPROP_FONT, lFontName);
        ObjectSetString(ChartID(), oStats, OBJPROP_TEXT, oStats);
    }
    ObjectCreate(ChartID(), oCS, OBJ_LABEL, ChartWindowFind(ChartID(), iName), 0, 0.0);
    ObjectSetInteger(ChartID(), oCS, OBJPROP_CORNER, lCorner);
    ObjectSetInteger(ChartID(), oCS, OBJPROP_XDISTANCE, oDistX);
    ObjectSetInteger(ChartID(), oCS, OBJPROP_YDISTANCE,  (
                         (oStatsShow ? ((lFontSize + oSpacingY) + oDistY) : oDistY)
                     ));
    ObjectSetInteger(ChartID(), oCS, OBJPROP_FONTSIZE, lFontSize);
    ObjectSetInteger(ChartID(), oCS, OBJPROP_COLOR, lColor);
    ObjectSetString(ChartID(), oCS, OBJPROP_FONT, lFontName);
    ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, oCS);
    if(dShowLocal && !dShowSameLine) {
        ObjectCreate(ChartID(), oCL, OBJ_LABEL, ChartWindowFind(ChartID(), iName), 0, 0.0);
        ObjectSetInteger(ChartID(), oCL, OBJPROP_CORNER, lCorner);
        ObjectSetInteger(ChartID(), oCL, OBJPROP_XDISTANCE, oDistX);
        ObjectSetInteger(ChartID(), oCL, OBJPROP_YDISTANCE, (
                             (oStatsShow ? ((2 * (lFontSize + oSpacingY)) + oDistY) : ((lFontSize + oSpacingY) + oDistY))
                         ));
        ObjectSetInteger(ChartID(), oCL, OBJPROP_FONTSIZE, lFontSize);
        ObjectSetInteger(ChartID(), oCL, OBJPROP_COLOR, lColor);
        ObjectSetString(ChartID(), oCL, OBJPROP_FONT, lFontName);
        ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, oCL);
    }
    ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER;
    switch (lCorner) {
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
    if(oStatsShow) {
        ObjectSetInteger(ChartID(), oStats, OBJPROP_ANCHOR, anchor);
    }
    ObjectSetInteger(ChartID(), oCS, OBJPROP_ANCHOR, anchor);
    if(dShowLocal && !dShowSameLine) {
        ObjectSetInteger(ChartID(), oCL, OBJPROP_ANCHOR, anchor);
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
    ObjectDelete(ChartID(), oStats);
    ObjectDelete(ChartID(), oCS);
    ObjectDelete(ChartID(), oCL);
    EventKillTimer();
    return;
}
//+------------------------------------------------------------------+
// Timer function
//+------------------------------------------------------------------+
void OnTimer()
{
// Issue: Sometimes IsStopped() is set, but the platform still calls for the OnTimer():
//  ERROR: ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS, ChartWindowFind(ChartID(), iName), chartSizeXTemp) at "OnTimer:156", last internal error: 4022 (Mini Charts.mq5)
//  This check attempts to fix that issue
    if(IsStopped()) {
        return;
    }
// This is a mess, becuz there are more than 7 booleans and variations of formatting - but it is highly compiler friendly anyway (if the compiler knows about conditional graph optimization)
    if(!dShowLocal && !dShowOffset) {
        ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)));
    } else if(!dShowLocal && dShowOffset) {
        ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()));
    } else if(dShowLocal && dShowSameLine && (dFormat == kTimeSeconds || dFormat == kTimeDateSeconds)) {
        if(!dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeToString(TimeLocal(), TIME_SECONDS));
        } else if(dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeToString(TimeGMT(), TIME_SECONDS));
        } else if(!dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeToString(TimeLocal(), EnumToInt(dFormat)));
        } else if(dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeToString(TimeGMT(), EnumToInt(dFormat)));
        } else if(!dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), TIME_SECONDS) + " " + TimeGMTOffset(TimeLocal()));
        } else if(dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), TIME_SECONDS) + " " + TimeGMTOffset(TimeGMT()));
        } else if(!dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeLocal()));
        } else if(dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_SECONDS) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeGMT()));
        } else {
            ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
        }
    } else if(dShowLocal && dShowSameLine && (dFormat == kTimeMinutes || dFormat == kTimeDateMinutes)) {
        if(!dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeToString(TimeLocal(), TIME_MINUTES));
        } else if(dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeToString(TimeGMT(), TIME_MINUTES));
        } else if(!dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeToString(TimeLocal(), EnumToInt(dFormat)));
        } else if(dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeToString(TimeGMT(), EnumToInt(dFormat)));
        } else if(!dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), TIME_MINUTES) + " " + TimeGMTOffset(TimeLocal()));
        } else if(dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), TIME_MINUTES) + " " + TimeGMTOffset(TimeGMT()));
        } else if(!dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeLocal(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeLocal()));
        } else if(dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_MINUTES) + " " + TimeGMTOffset(TimeTradeServer()) + " " + TimeToString(TimeGMT(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeGMT()));
        } else {
            ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
        }
    } else if(dShowLocal && !dShowSameLine) {
        if(!dShowLocalAsUTC && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString(TimeLocal(), EnumToInt(dFormat)));
        } else if(!dShowLocalAsUTC && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString(TimeLocal(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeLocal()));
        } else if (dShowLocalAsUTC && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString(TimeGMT(), EnumToInt(dFormat)));
        } else if (dShowLocalAsUTC && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeTradeServer()));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString(TimeGMT(), EnumToInt(dFormat)) + " " + TimeGMTOffset(TimeGMT()));
        } else {
            ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
        }
    } else {
        ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
    }
    if(last < TimeGMT()) {
        statsUpdate(); // Has last = TimeGMT();
        ChartRedraw(); // After OnTimer() returns, the platform does not call ChartRedraw(), so we have to call here
    }
    return;
}
//+------------------------------------------------------------------+
// Calculation function
// Issue: Week Range is not updated on a closed market, when opening the platform from fresh boot, because iLow() and iHigh() return wrong data (0.0) - this is one of the issues with MT5 parallel loading of background chart data (I love parallelism, but only when I have control of it, or atleast know its state).
//  Fixed by: making statsUpdate() independent and called at onTimer()
//+------------------------------------------------------------------+
int OnCalculate(
    const int        rates_total,
    const int        prev_calculated,
    const int        begin,
    const double&    price[])

{
    if(!oStatsShow || (rates_total <= 2)) { // No need to calculate if the data is less than the minimum operational period, or oStatsShow is false - it is returned as 0, because we want the terminal to interpret that we still need to calculate (performance cost is likely unmensurable)
        return 0;
    }
    statsUpdate();
//ChartRedraw(); // Performance loss is HUGE on every Tick - also, after OnCalculate is returned (such event called only on a Tick, calculation), the platform itself executes a ChartRedraw() and processes the object queue - doing a ChartRedraw() here is just a waste of CPU cycles
    return rates_total; // Calculations are done and valid
}
//+------------------------------------------------------------------+
//
//+------------------------------------------------------------------+
void statsUpdate()
{
    last = TimeGMT();
    datetime m = ((iTime(Symbol(), PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent()) < 0) ? 0 : (iTime(Symbol(), PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent());
    datetime s = m % 60;
    m = (m - s) / 60;
    if(sFormat == kFirst) {
        ObjectSetString(ChartID(), oStats, OBJPROP_TEXT,
                        "Ampl(" +
                        DoubleToString(iHigh(Symbol(), PERIOD_CURRENT, 1) - iLow(Symbol(), PERIOD_CURRENT, 1), Digits()) +
                        "/" +
                        DoubleToString(iHigh(Symbol(), PERIOD_CURRENT, 0) - iLow(Symbol(), PERIOD_CURRENT, 0), Digits()) +
                        ")/D1(" +
                        DoubleToString((iHigh(Symbol(), PERIOD_D1, 1) - iLow(Symbol(), PERIOD_D1, 1)), Digits()) +
                        "/" +
                        DoubleToString((iHigh(Symbol(), PERIOD_D1, 0) - iLow(Symbol(), PERIOD_D1, 0)), Digits()) +
                        ") Spr(" +
                        IntegerToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)) +
                        (SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 10 ? "..." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 100 ? ".." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 1000 ? "." : "") +
                        ") " +
                        (m < 10 ? "0" : "") +
                        IntegerToString((m < 0 ? 0 : m)) +
                        ":" +
                        (s < 10 ? "0" : "") +
                        IntegerToString((s < 0 ? 0 : s))
                       );
    } else if(sFormat == kSecond) {
        ObjectSetString(ChartID(), oStats, OBJPROP_TEXT,
                        "Chg(" +
                        DoubleToString((iClose(Symbol(), PERIOD_D1, 2) ? ((iClose(Symbol(), PERIOD_D1, 1) * 100.0 / iClose(Symbol(), PERIOD_D1, 2)) - 100.0) : 0.0), 2) + "%/" + /* Check for Division by Zero, skips calculation if true - unfortunately MQL5 does not follow IEEE 754 Standards, which enforces no error at "zero divide in", such case of 0.0/0.0 should have resulted in NaN and happens because of the platform asynchronous nature of loading different timeframes than the current */
                        DoubleToString((iClose(Symbol(), PERIOD_D1, 1) ? ((iClose(Symbol(), PERIOD_D1, 0) * 100.0 / iClose(Symbol(), PERIOD_D1, 1)) - 100.0) : 0.0), 2) +
                        "%) W" +
                        IntegerToString(weekRange) + "[" + DoubleToString(iLow(Symbol(), PERIOD_W1, iLowest(Symbol(), PERIOD_W1, MODE_LOW, weekRange, 0)), Digits()) +
                        ", " +
                        DoubleToString(iHigh(Symbol(), PERIOD_W1, iHighest(Symbol(), PERIOD_W1, MODE_HIGH, weekRange, 0)), Digits()) +
                        "] Spr(" +
                        IntegerToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)) +
                        (SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 10 ? "..." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 100 ? ".." : SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) < 1000 ? "." : "") +
                        ") " +
                        (m < 10 ? "0" : "") +
                        IntegerToString((m < 0 ? 0 : m)) +
                        ":" +
                        (s < 10 ? "0" : "") +
                        IntegerToString((s < 0 ? 0 : s))
                       );
    } else {
        ErrorPrint("not implemented");
    }
    return;
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
