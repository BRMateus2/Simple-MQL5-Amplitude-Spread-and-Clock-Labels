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
//|                     Copyright (C) 2021, Mateus Matucuma Teixeira |
//|                                            mateusmtoss@gmail.com |
//| GNU General Public License version 2 - GPL-2.0                   |
//| https://opensource.org/licenses/gpl-2.0.php                      |
//+------------------------------------------------------------------+
// https://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels/
//---- Main Properties
#property copyright "2021, Mateus Matucuma Teixeira"
#property link "https://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels/"
#property description "This simple indicator is just a statistical label showing Last and Current Candle Amplitude (MinMax), Last and Current Day Amplitude, Current Tick Amplitude and Time Remaining for next Candle.\n"
#property description "It also shows Server Time (Market Watch) and Local PC Time so you can focus more on the graph and adapt to market hours.\n"
#property description "You can get the source code at \n\thttps://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels/"
#property version "1.07"
#property fpfast
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0
//---- Imports
//---- Include Libraries and Modules
//#include <MT-Utilities.mqh>
//---- Definitions
#ifndef ErrorPrint
#define ErrorPrint(Dp_error) Print("ERROR: " + Dp_error + " at \"" + __FUNCTION__ + ":" + IntegerToString(__LINE__) + "\", last internal error: " + IntegerToString(GetLastError()) + " (" + __FILE__ + ")"); ResetLastError(); DebugBreak(); // It should be noted that the GetLastError() function doesn't zero the _LastError variable. Usually the ResetLastError() function is called before calling a function, after which an error appearance is checked.
#endif
//#define INPUT const
#ifndef INPUT
#define INPUT input
#endif
//---- Input Parameters
//---- "Label Settings"
input group "Label Settings"
const string iName = "StatsAndClock";
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
    kSFormatFirst, // Format Ampl(xA/xB)/(yA/yB) Spr(z) mm:ss - Amplitude/Spread
    kSFormatSecond // Format Chg(dA/dB) W([m,M]) Spr(z) mm:ss - Chg/WeekRange/Spread
};
INPUT int weekRange = 52; // How many weeks should the range contain? Normally 52 weeks
INPUT SFormat sFormat = kSFormatSecond; // Amplitude and Spread Stats Format
INPUT bool oStatsShowMktClosed = true; // If there is no new ticks, show "Closed"/"Disconnected"?
INPUT int oStatsShowMktClosedTimer = 60; // Inactivity timer in seconds, for "Closed"/"Disconnected"
//---- "Clock"
input group "Clock"
enum DateFormat {
    kDateFormatSeconds, // Format hh:mm:ss
    kDateFormatMinutes, // Format hh:mm
    kDateFormatDateSeconds, // Format YYYY.MM.DD hh:mm:ss
    kDateFormatDateMinutes, // Format YYYY.MM.DD hh:mm
};
INPUT DateFormat dFormat = kDateFormatDateSeconds; // Date Format
INPUT bool dShowOffset = true; // Show UTC Timezone Offset?
INPUT bool dShowSameLine = true; // Show both dates on the same line?
//---- "Server Clock"
input group "Server Clock"
INPUT bool dUseServer = true; // Use Server Date instead of Local/UTC Date?
INPUT int dServerOffset = 0; // Offset in seconds
INPUT bool oCSLatencyAppend = false; // DEBUG: append latency of the last 20 calls to Server Label
INPUT bool oCSLatencyHP = false; // DEBUG: use 1ms OnTimer() instead of power-saving 1000ms
//---- "Local Clock"
input group "Local Clock"
INPUT bool dShowLocal = true; // Show Local Time Label?
INPUT bool dShowLocalAsUTC = false; // Use UTC+0 / GMT Time instead of Local Timezone?
INPUT int dLocalOffset = 0; // Offset in seconds
//---- "Alerts"
//input group "TODO Alerts"
//INPUT bool enableAlertMkt = true; // Enable Market Open and Market Close Alerts
//bool enableAlertMktOpen = false; // Auxiliary
//---- Objects
const string oStats = "MTCAmplitudeAndSpread"; // Object Stats, used for naming
const string oCS = "MTCServer"; // Object Clock Server, used for naming
const string oCL = "MTCLocal"; // Object Clock Local, used for naming
//---- OnTimer() statsUpdate() optimization, calls once per second, if for some reason the Stats object was missing data
datetime last = 0;
//---- Special oCSLatencyAppend, not guaranteed to average correctly if GetMicrosecondCount() returns 0
static ulong getMicrosecondCountBuf[20] = {};
static ulong getMicrosecondCountLast = 0;
static uint getMicrosecondCountI = 0;
static uint getMicrosecondCountJ = 0;
static ulong getMicrosecondCountMean = 0;
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Constructor or initialization function
// https://www.mql5.com/en/docs/basis/function/events
// https://www.mql5.com/en/articles/100
//+------------------------------------------------------------------+
int OnInit()
{
    // Issue: When switching Timeframes too fast, Queued ObjectDelete() is called before or after OnTick() from the Object Event Queue, after ObjectCreate() from OnInit(), deleting the object
    //  Fix: unknown
    last = TimeGMT();
    getMicrosecondCountLast = GetMicrosecondCount();
    // Indicator Subwindow Short Name
    IndicatorSetString(INDICATOR_SHORTNAME, iName);
    // Treat Objects
    if(oStatsShow) {
        if(!ObjectCreate(ChartID(), oStats, OBJ_LABEL, ChartWindowFind(ChartID(), iName), 0, 0.0)) {
            ErrorPrint("Object creation with ChartID() " + IntegerToString(ChartID()) + " at window " + IntegerToString(ChartWindowFind(ChartID(), iName)));
        }
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
    if(oCSLatencyHP) {
        if(!EventSetMillisecondTimer(1)) {
            ErrorPrint("!EventSetMillisecondTimer(1) failure at subscribing to event timer"); // Create Timer Event in seconds (use EventSetMillisecondTimer for higher precision or HFT/High Frequency Trading)
            return INIT_FAILED;
        }
    } else if(!EventSetTimer(1)) {
        ErrorPrint("!EventSetTimer(1) failure at subscribing to event timer");
        return INIT_FAILED;
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
    //  ERROR: ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS, ChartWindowFind(ChartID(), iName), chartSizeXTemp) at "OnTimer", last internal error: 4022 (Mini Charts.mq5)
    //  This check attempts to fix that issue
    if(IsStopped()) {
        return;
    }
    // This is a mess, becuz there are more than 7 booleans and variations of formatting - but it is highly compiler friendly anyway (if the compiler knows about conditional graph optimization)
    if(!dShowLocal && !dShowOffset) {
        ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)));
    } else if(!dShowLocal && dShowOffset) {
        ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)));
    } else if(dShowLocal && dShowSameLine && (dFormat == kDateFormatSeconds || dFormat == kDateFormatDateSeconds)) {
        if(!dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeToString((TimeLocal() + dLocalOffset), TIME_SECONDS));
        } else if(dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeToString((TimeGMT() + dLocalOffset), TIME_SECONDS));
        } else if(!dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_SECONDS) + " " + TimeToString((TimeLocal() + dLocalOffset), EnumToInt(dFormat)));
        } else if(dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_SECONDS) + " " + TimeToString((TimeGMT() + dLocalOffset), EnumToInt(dFormat)));
        } else if(!dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeLocal() + dLocalOffset), TIME_SECONDS) + " " + TimeGMTOffset((TimeLocal() + dLocalOffset)));
        } else if(dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeGMT() + dLocalOffset), TIME_SECONDS) + " " + TimeGMTOffset((TimeGMT() + dLocalOffset)));
        } else if(!dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_SECONDS) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeLocal() + dLocalOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeLocal() + dLocalOffset)));
        } else if(dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_SECONDS) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeGMT() + dLocalOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeGMT() + dLocalOffset)));
        } else {
            ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
        }
    } else if(dShowLocal && dShowSameLine && (dFormat == kDateFormatMinutes || dFormat == kDateFormatDateMinutes)) {
        if(!dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeToString((TimeLocal() + dLocalOffset), TIME_MINUTES));
        } else if(dShowLocalAsUTC && dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeToString((TimeGMT() + dLocalOffset), TIME_MINUTES));
        } else if(!dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_MINUTES) + " " + TimeToString((TimeLocal() + dLocalOffset), EnumToInt(dFormat)));
        } else if(dShowLocalAsUTC && !dUseServer && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_MINUTES) + " " + TimeToString((TimeGMT() + dLocalOffset), EnumToInt(dFormat)));
        } else if(!dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeLocal() + dLocalOffset), TIME_MINUTES) + " " + TimeGMTOffset((TimeLocal() + dLocalOffset)));
        } else if(dShowLocalAsUTC && dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeGMT() + dLocalOffset), TIME_MINUTES) + " " + TimeGMTOffset((TimeGMT() + dLocalOffset)));
        } else if(!dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_MINUTES) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeLocal() + dLocalOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeLocal() + dLocalOffset)));
        } else if(dShowLocalAsUTC && !dUseServer && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), TIME_MINUTES) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)) + " " + TimeToString((TimeGMT() + dLocalOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeGMT() + dLocalOffset)));
        } else {
            ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
        }
    } else if(dShowLocal && !dShowSameLine) {
        if(!dShowLocalAsUTC && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString((TimeLocal() + dLocalOffset), EnumToInt(dFormat)));
        } else if(!dShowLocalAsUTC && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString((TimeLocal() + dLocalOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeLocal() + dLocalOffset)));
        } else if (dShowLocalAsUTC && !dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString((TimeGMT() + dLocalOffset), EnumToInt(dFormat)));
        } else if (dShowLocalAsUTC && dShowOffset) {
            ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, TimeToString((TimeTradeServer() + dServerOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeTradeServer() + dServerOffset)));
            ObjectSetString(ChartID(), oCL, OBJPROP_TEXT, TimeToString((TimeGMT() + dLocalOffset), EnumToInt(dFormat)) + " " + TimeGMTOffset((TimeGMT() + dLocalOffset)));
        } else {
            ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
        }
    } else {
        ErrorPrint("untreated condition with dShowLocal: \"" + (string) dShowLocal + "\" " + "dShowOffset: \"" + (string) dShowOffset + "\" " + "dShowSameLine: \"" + (string) dShowSameLine + "\" " + "dFormat: \"" + EnumToString(dFormat) + "\" " + "dShowLocalAsUTC: \"" + (string) dShowLocalAsUTC + "\" " + "dUseServer: \"" + (string) dUseServer + "\" " + "\"");
    }
    if(last < TimeGMT() && oStatsShow) { // OnTimer() statsUpdate() optimization, calls once per second, if for some reason the Stats object was missing data
        statsUpdate(); // Has last = TimeGMT();
    }
    if(oCSLatencyAppend) { // Special oCSLatencyAppend, not guaranteed to average correctly if GetMicrosecondCount() returns 0
        // Calculate latency of the last 20 calls to OnTimer() and show as a tooltip and also append to the text
        // The code is highly optimized (at least the comparisons), that's the reason for > in place of >= - normally there is no reason to optimize these operations at all, but I can't output the code in Assembly to look at, neither this code can be benchmarked usefully
        getMicrosecondCountBuf[getMicrosecondCountI++] = GetMicrosecondCount() - getMicrosecondCountLast;
        if(getMicrosecondCountI > 19) {
            getMicrosecondCountI = 0;
        }
        for(getMicrosecondCountJ = 0, getMicrosecondCountMean = 0; getMicrosecondCountJ < 20 && getMicrosecondCountBuf[getMicrosecondCountJ] > 0; getMicrosecondCountJ++) {
            getMicrosecondCountMean = getMicrosecondCountMean + getMicrosecondCountBuf[getMicrosecondCountJ];
        }
        getMicrosecondCountMean = getMicrosecondCountMean / (getMicrosecondCountJ * 1000);
        ObjectSetString(ChartID(), oCS, OBJPROP_TOOLTIP, ("Last 20 calls latency of OnTimer(): " + IntegerToString(getMicrosecondCountMean) + "ms"));
        ObjectSetString(ChartID(), oCS, OBJPROP_TEXT, (ObjectGetString(ChartID(), oCS, OBJPROP_TEXT) + " " + IntegerToString(getMicrosecondCountMean) + "ms"));
        getMicrosecondCountLast = GetMicrosecondCount();
        // Also lets just append Server Latency and Retransmissions to the tooltip of oStats, for the sake of it
        if(oStatsShow) {
            ObjectSetString(ChartID(), oStats, OBJPROP_TOOLTIP, ("Server Latency: " + IntegerToString(TerminalInfoInteger(TERMINAL_PING_LAST)) + "us" + "/Packet Retransmissions: " + DoubleToString(TerminalInfoDouble(TERMINAL_RETRANSMISSION), 2) + "%"));
        }
    }
    // After OnTimer() returns, the platform does not call ChartRedraw(), so we have to call ChartRedraw()
    ChartRedraw();
    return;
}
//+------------------------------------------------------------------+
// Calculation function
// Fixed Issue: Week Range is not updated on a closed market, when opening the platform from fresh boot, because iLow() and iHigh() return wrong data (0.0) - this is one of the issues with MT5 parallel loading of background chart data (I love parallelism, but only when I have control of it, or at least know its state).
//  Fixed by: making statsUpdate() independent and called at onTimer()
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
    if(!oStatsShow || (rates_total <= 2)) { // No need to calculate if the data is less than the minimum operational period, or oStatsShow is false - it is returned as 0, because we want the terminal to interpret that we still need to calculate (performance cost is likely unmensurable, or maybe the same as returning any value at all)
        return 0;
    }
    statsUpdate();
    //ChartRedraw(); // Performance loss is HUGE on every Tick - also, after OnCalculate is returned (such event called only on a Tick, calculation), the platform itself executes a ChartRedraw() and processes the object queue - doing a ChartRedraw() here is just a waste of CPU cycles
    return rates_total; // Calculations are done and valid
}
//+------------------------------------------------------------------+
// Statistical Label Updater
//+------------------------------------------------------------------+
void statsUpdate()
{
    last = TimeGMT();
    ulong m = (ulong) (((iTime(Symbol(), PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) - TimeTradeServer()) < 0) ? 0 : (iTime(Symbol(), PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) - TimeTradeServer()));
    ulong s = m % 60;
    m = (m - s) / 60;
    if(sFormat == kSFormatFirst) {
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
                        ((
                             (
                                 (SymbolInfoInteger(Symbol(), SYMBOL_TIME) < (TimeCurrent() - oStatsShowMktClosedTimer)) || (oStatsShowMktClosedTimer < (TimeTradeServer() - TimeCurrent()))
                             ) && oStatsShowMktClosed && TerminalInfoInteger(TERMINAL_CONNECTED)) ? "Mkt Closed" :
                         (oStatsShowMktClosed && !TerminalInfoInteger(TERMINAL_CONNECTED)) ? "Disconnected" : (
                             (m < 10 ? "0" : "") +
                             IntegerToString((m < 0 ? 0 : m)) +
                             ":" +
                             (s < 10 ? "0" : "") +
                             IntegerToString((s < 0 ? 0 : s))
                         ))
                       );
    } else if(sFormat == kSFormatSecond) {
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
                        ((
                             (
                                 (SymbolInfoInteger(Symbol(), SYMBOL_TIME) < (TimeCurrent() - oStatsShowMktClosedTimer)) || (oStatsShowMktClosedTimer < (TimeTradeServer() - TimeCurrent()))
                             ) && oStatsShowMktClosed && TerminalInfoInteger(TERMINAL_CONNECTED)) ? "Mkt Closed" :
                         (oStatsShowMktClosed && !TerminalInfoInteger(TERMINAL_CONNECTED)) ? "Disconnected" : (
                             (m < 10 ? "0" : "") +
                             IntegerToString((m < 0 ? 0 : m)) +
                             ":" +
                             (s < 10 ? "0" : "") +
                             IntegerToString((s < 0 ? 0 : s))
                         ))
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
// Extra functions, utilities and conversion
//+------------------------------------------------------------------+
int EnumToInt(DateFormat e)
{
    if(e == kDateFormatSeconds) {
        return TIME_SECONDS;
    } else if(e == kDateFormatMinutes) {
        return TIME_MINUTES;
    } else if(e == kDateFormatDateSeconds) {
        return TIME_DATE | TIME_SECONDS;
    } else if(e == kDateFormatDateMinutes) {
        return TIME_DATE | TIME_MINUTES;
    }
    return -1;
}
//+------------------------------------------------------------------+
// Header Guard #endif
//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
