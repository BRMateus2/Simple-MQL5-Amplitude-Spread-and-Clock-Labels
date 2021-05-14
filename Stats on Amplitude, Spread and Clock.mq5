/*
Copyright (C) 2021 Mateus Matucuma Teixeira

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/
//+------------------------------------------------------------------+
//|                         Stats on Amplitude, Spread and Clock.mq5 |
//|                         Copyright 2021, Mateus Matucuma Teixeira |
//|                                            mateusmtoss@gmail.com |
//| GNU General Public License version 2 - GPL-2.0                   |
//| https://opensource.org/licenses/gpl-2.0.php                      |
//+------------------------------------------------------------------+
// https://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels
#property indicator_chart_window
#property indicator_plots 0
#property strict
#property copyright "2021, Mateus Matucuma Teixeira"
#property link "https://github.com/BRMateus2/"
#property description "This simple indicator is just a statistical label showing Last and Current Candle Amplitude (MinMax), Last and Current Day Amplitude, Current Tick Amplitude and Time Remaining for next Candle. It also shows Server Time (Market Watch) and Local PC Time so you can focus more on the graph and adapt to market hours. You can get the source code at https://github.com/BRMateus2/Simple-MQL5-Amplitude-Spread-and-Clock-Labels/."
//---- input parameters
input color textColor = clrYellow; // Text Color
input ENUM_BASE_CORNER corner = CORNER_RIGHT_UPPER; // Text Corner
input int fontSize = 12; // Font Size
input string fontName = "DejaVu Sans Mono"; // Font Name (system naming)
input bool showAmplitudeAndSpread = true; // Show Amplitude and Spread line?
input int xDistance = 0; // X Distance or Horizontal Position Offset
input int yDistance = 0; // Y Distance or Vertical Position Offset
input int ySpacing = 3; // Gap between texts
input bool showLocal = true; // Show Local Time?
enum DateFormat {
    TimeSeconds, // Format HH:MM:SS
    TimeMinutes, // Format HH:MM
    TimeDateSeconds, // Format yyyy.mm.dd HH:MM:SS
    TimeDateMinutes, // Format yyyy.mm.dd HH:MM
};
input DateFormat dateFormat = TimeDateSeconds; // Date Format
input bool showDatesSameLine = true; // Show both dates on the same line?
//---- other parameters
string objPrimary = "Amplitude&Spread";
string objClockServer = "ClockServer";
string objClockLocal = "ClockCurrent";
//+------------------------------------------------------------------+
int EnumToInt(DateFormat e)
{
    if(e == TimeSeconds) {
        return TIME_SECONDS;
    } else if(e == TimeMinutes) {
        return TIME_MINUTES;
    } else if(e == TimeDateSeconds) {
        return TIME_DATE | TIME_SECONDS;
    } else if(e == TimeDateMinutes) {
        return TIME_DATE | TIME_MINUTES;
    }
    return -1;
}
//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if(showAmplitudeAndSpread) {
        ObjectCreate(0, objPrimary, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, objPrimary, OBJPROP_CORNER, corner);
        ObjectSetInteger(0, objPrimary, OBJPROP_XDISTANCE, xDistance);
        ObjectSetInteger(0, objPrimary, OBJPROP_YDISTANCE, yDistance);
        ObjectSetInteger(0, objPrimary, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objPrimary, OBJPROP_COLOR, textColor);
        ObjectSetString(0, objPrimary, OBJPROP_FONT, fontName);
        ObjectSetInteger(0, objPrimary, OBJPROP_BACK, false);
    }
    ObjectCreate(0, objClockServer, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, objClockServer, OBJPROP_CORNER, corner);
    ObjectSetInteger(0, objClockServer, OBJPROP_XDISTANCE, xDistance);
    ObjectSetInteger(0, objClockServer, OBJPROP_YDISTANCE, ((fontSize + ySpacing) + yDistance));
    ObjectSetInteger(0, objClockServer, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, objClockServer, OBJPROP_COLOR, textColor);
    ObjectSetString(0, objClockServer, OBJPROP_FONT, fontName);
    ObjectSetInteger(0, objClockServer, OBJPROP_BACK, false);
    if(showLocal && !showDatesSameLine) {
        ObjectCreate(0, objClockLocal, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, objClockLocal, OBJPROP_CORNER, corner);
        ObjectSetInteger(0, objClockLocal, OBJPROP_XDISTANCE, xDistance);
        ObjectSetInteger(0, objClockLocal, OBJPROP_YDISTANCE, ((2 * (fontSize + ySpacing)) + yDistance));
        ObjectSetInteger(0, objClockLocal, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objClockLocal, OBJPROP_COLOR, textColor);
        ObjectSetString(0, objClockLocal, OBJPROP_FONT, fontName);
        ObjectSetInteger(0, objClockLocal, OBJPROP_BACK, false);
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
    ObjectSetInteger(0, objPrimary, OBJPROP_ANCHOR, anchor);
    ObjectSetInteger(0, objClockServer, OBJPROP_ANCHOR, anchor);
    if(showLocal && !showDatesSameLine) {
        ObjectSetInteger(0, objClockLocal, OBJPROP_ANCHOR, anchor);
    }
    EventSetMillisecondTimer(1000);
    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(showAmplitudeAndSpread) {
        ObjectDelete(0, objPrimary);
    }
    ObjectDelete(0, objClockServer);
    if(showLocal && !showDatesSameLine) {
        ObjectDelete(0, objClockLocal);
    }
    EventKillTimer();
    return;
}
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!showLocal) {
        ObjectSetString(0, objClockServer, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dateFormat)));
    } else if(showLocal && showDatesSameLine && (dateFormat == TimeSeconds || dateFormat == TimeDateSeconds)) {
        ObjectSetString(0, objClockServer, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dateFormat)) + " " + TimeToString(TimeLocal(), TIME_SECONDS));
    } else if(showLocal && showDatesSameLine && (dateFormat == TimeMinutes || dateFormat == TimeDateMinutes)) {
        ObjectSetString(0, objClockServer, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dateFormat)) + " " + TimeToString(TimeLocal(), TIME_MINUTES));
    } else if(showLocal && !showDatesSameLine) {
        ObjectSetString(0, objClockServer, OBJPROP_TEXT, TimeToString(TimeTradeServer(), EnumToInt(dateFormat)));
        ObjectSetString(0, objClockLocal, OBJPROP_TEXT, TimeToString(TimeLocal(), EnumToInt(dateFormat)));
    }
    return;
}
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime& time[], const double& open[], const double& high[], const double& low[], const double& close[], const long& tick_volume[], const long& volume[], const int& spreads[])
{
    if(!showAmplitudeAndSpread) {
        return rates_total;
    }
    ArraySetAsSeries(time, true);
    int m = int(time[0] + PeriodSeconds() - TimeCurrent());
    int s = m % 60;
    m = (m - s) / 60;
    long spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
    string _sp = "", _m = "", _s = "";
    if (spread < 10) _sp = "...";
    else if (spread < 100) _sp = "..";
    else if (spread < 1000) _sp = ".";
    if (m < 10) _m = "0";
    if (s < 10) _s = "0";
    if (m < 0) m = 0;
    if (s < 0) s = 0;
    ObjectSetString(0, objPrimary, OBJPROP_TEXT,
                    "Ampl(" + DoubleToString((iHigh(NULL, 0, 1) - iLow(NULL, 0, 1)), Digits()) + "/" + DoubleToString((iHigh(NULL, 0, 0) - iLow(NULL, 0, 0)), Digits()) + ")" +
                    "/D1(" + DoubleToString((iHigh(NULL, PERIOD_D1, 1) - iLow(NULL, PERIOD_D1, 1)), Digits()) + "/" + DoubleToString((iHigh(NULL, PERIOD_D1, 0) - iLow(NULL, PERIOD_D1, 0)), Digits()) + ")" +
                    /*" Chg(" + DoubleToString(((((iClose(NULL, 0, 1) / iOpen(NULL, 0, 1)) - 1) * 100)), 1) + "%/" + DoubleToString(((((iClose(NULL,0,0) / iOpen(NULL,0,0)) - 1) * 100)), 1) + "%)" +*/
                    " Spr(" + IntegerToString(spread) + _sp + ") " + _m + IntegerToString(m) + ":" + _s + IntegerToString(s)
                   );
    return rates_total;
}
//+------------------------------------------------------------------+
