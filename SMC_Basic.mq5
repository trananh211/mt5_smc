//+------------------------------------------------------------------+
//|                                                    SMC_Basic.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
   CTrade Trade;
int barsTotal;

input double risk2reward = 2;
input double Lots = 0.01;

input double breakeventTrigger = 5000;
input double breakevent = 2000;


// swing 
double Highs[], Lows[];
datetime HighsTime[], LowsTime[];

int LastSwingMeter = 0;

// FVG
double BuFVGHighs[], BuFVGLows[];
datetime BuFVGTime[];

double BeFVGHighs[], BeFVGLows[];
datetime BeFVGTime[];

double handlesma;

int lastTimeH = 0;
int prevTimeH = 0;
int lastTimeL = 0;
int prevTimeL = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(Highs, true);
   ArraySetAsSeries(Lows, true);
   ArraySetAsSeries(HighsTime, true);
   ArraySetAsSeries(LowsTime, true);
   
   ArraySetAsSeries(BuFVGHighs, true);
   ArraySetAsSeries(BuFVGLows, true);
   ArraySetAsSeries(BuFVGTime, true);
   
   ArraySetAsSeries(BeFVGHighs, true);
   ArraySetAsSeries(BeFVGLows, true);
   ArraySetAsSeries(BeFVGTime, true);
   
   handlesma = iMA(_Symbol, PERIOD_H1, 89, 0, MODE_SMA, PRICE_CLOSE);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if (barsTotal != bars) {
      barsTotal = bars;
      
      // SMA INDICATOR BUFFER
      double sma[];
      ArraySetAsSeries(sma, true);
      CopyBuffer(handlesma, MAIN_LINE, 0, 9, sma);
      
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, rates);
      
      int SwingSignal = swingPoints();
      FVG();
      
      // TEst Buy
      if (
         ArraySize(Lows) > 1 &&
         ArraySize(BuFVGHighs) > 0 &&
         ArraySize(HighsTime) > 0 &&
         
         Lows[0] > sma[1] && // filter sma
         
         Lows[0] < BuFVGHighs[0] &&
         BuFVGTime[0] > LowsTime[1] && 
         BuFVGTime[0] < HighsTime[0] &&
         Lows[0] > Lows[1] &&
         LowsTime[0] > HighsTime[0] && 
         rates[1].close > rates[0].open &&
         SwingSignal > 0
      ) {
         double entryprice = rates[1].close;
         entryprice = NormalizeDouble(entryprice, _Digits);
         
         double stoploss = Lows[1];
         stoploss = NormalizeDouble(stoploss, _Digits);
         
         double riskvalue =  entryprice - stoploss;
         riskvalue = NormalizeDouble(riskvalue, _Digits);
         
         double takeprofit = entryprice + (risk2reward * riskvalue);
         takeprofit = NormalizeDouble(takeprofit, _Digits);
         Trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, Lots, entryprice, stoploss, takeprofit, "Buy Test");
         
      }
      
      // Test Sell
      if (
         ArraySize(Highs) > 1 &&
         ArraySize(BeFVGLows) > 0 &&
         ArraySize(LowsTime) > 0 &&
         
         Highs[0] < sma[1] && // filter sma
         
         Highs[0] < BeFVGLows[0] &&
         BeFVGTime[0] < LowsTime[1] &&
         BeFVGTime[0] > HighsTime[0] && 
         
         Highs[0] < Highs[1] &&
         LowsTime[0] < HighsTime[0] && 
         rates[1].close < rates[0].open &&
         SwingSignal < 0
      ) {
         double entryprice = rates[1].close;
         entryprice = NormalizeDouble(entryprice, _Digits);
         
         double stoploss = Highs[1];
         stoploss = NormalizeDouble(stoploss, _Digits);
         
         double riskvalue =  stoploss - entryprice;
         riskvalue = NormalizeDouble(riskvalue, _Digits);
         
         double takeprofit = entryprice - (risk2reward * riskvalue);
         takeprofit = NormalizeDouble(takeprofit, _Digits);
         
         Trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, Lots, entryprice, stoploss, takeprofit, "Sell Test");
      }
      
      
      // BREAKEVENT TRIGGER
      for(int a = PositionsTotal() - 1; a >= 0; a--) {
         ulong positionTicketa = PositionGetTicket(a);
         if (PositionSelectByTicket(positionTicketa)) {
            double posSL = PositionGetDouble(POSITION_SL);
            double posTP = PositionGetDouble(POSITION_TP);
            double posEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double posCurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            string tradeSymbol = PositionGetString(POSITION_SYMBOL);
            if ( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               
               double breakeventTriggerB = (posEntryPrice + breakeventTrigger*_Point);
               breakeventTriggerB = NormalizeDouble(breakeventTriggerB, _Digits);
               
               double newSlB = (posEntryPrice + breakevent*_Point);
               newSlB = NormalizeDouble(newSlB, _Digits);
               
               //Print(tradeSymbol+" - Checking Buy:" + breakeventTriggerB +" < "+posCurrentPrice);
               if (tradeSymbol == _Symbol && posCurrentPrice > breakeventTriggerB && posSL < posEntryPrice
                  ) {
                  if (Trade.PositionModify(positionTicketa, newSlB, posTP)) {
                     Print(__FUNCTION__, "Pos #",positionTicketa," WAS MODIFIED TO BREAKEVEN FOR BUY");
                  } else {
                     Print("[Error] Modify buy");
                  }
               }
            }
            
            if ( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
               
               double breakeventTriggerS = (posEntryPrice - breakeventTrigger*_Point);
               breakeventTriggerS = NormalizeDouble(breakeventTriggerS, _Digits);
               
               double newSlS = (posEntryPrice + breakevent*_Point);
               newSlS = NormalizeDouble(newSlS, _Digits);
               
               //Print(tradeSymbol+" - Checking Sell:"+ breakeventTriggerS +" > "+posCurrentPrice);
               if (tradeSymbol == _Symbol && posCurrentPrice < breakeventTriggerS && posSL > posEntryPrice
                  ) {
                  if (Trade.PositionModify(positionTicketa, newSlS, posTP)) {
                     Print(__FUNCTION__, "Pos #",positionTicketa," WAS MODIFIED TO BREAKEVEN FOR SELL");
                  } else {
                     Print("[Error] Modify Sell");
                  }
               }
            }
            
         }
      }
   }
  }
//+------------------------------------------------------------------+
// CREATE rectangle by the given coordinates
void createRect(  const long                 chart_ID=0,                // Chart ID
                  const string               name = "rectangleName",    // Rectangle Name
                  const int                  sub_window=0,              // sub window index
                  datetime time1=0, double price1 = 0,
                  datetime time2=0, double price2 = 0,
                  color    colorRect = clrRed, int directions = 0,
                  string   txt=0,
                  const ENUM_LINE_STYLE      style = STYLE_SOLID,       // Style of rectangle lines
                  const    int               width=1,                   // with of rectangle lines
                  const    bool              fill=false,                // fillling rectangle with color
                  const    bool              back=false,                // in the background
                  const    bool              selection= true,           // highlight to move
                  const    bool              hidden=true,               // hidden in the object list
                  const    long              z_order=0                  // priority for mouse click
) {
   string rectangleName = "";
   datetime time3 = iTime(_Symbol, PERIOD_CURRENT, 2);
   StringConcatenate(rectangleName, "FVG @", time3, "at", DoubleToString(price1,_Digits));
   if(ObjectCreate(0,rectangleName, OBJ_RECTANGLE, 0, time1, price1, time2, price2, colorRect, style, width, fill)) {
      //--- set rectangle color
      ObjectSetInteger(0, rectangleName, OBJPROP_COLOR, colorRect);
      //--- set the style of rectangle lines
      ObjectSetInteger(0, rectangleName, OBJPROP_STYLE, style);
      //--- set width of the rectangle lines
      ObjectSetInteger(0, rectangleName, OBJPROP_WIDTH, width);
      //--- enable (true) or disable (false) the mode of fillling the rectangle
      ObjectSetInteger(0, rectangleName, OBJPROP_FILL, fill);
      //--- display in the foreground (false) or background (true)
      ObjectSetInteger(0, rectangleName, OBJPROP_BACK, back);
      //--- enable (true) or disable (false) the mode of highlighting the rectangle for moving
      //--- when creating a graphical object using ObjetCreate function, the object cannot be
      //--- highlighted and moved by default. Inside this method, selection parameter
      //--- is true by default making it possible to highlight and move the object
      ObjectSetInteger(0, rectangleName, OBJPROP_SELECTABLE, selection);
      ObjectSetInteger(0, rectangleName, OBJPROP_SELECTED, selection);
      //--- hide (true) or display (false) graphical object name in the object list
      ObjectSetInteger(0, rectangleName, OBJPROP_HIDDEN, hidden);
      //--- set the priority for receiving the event of a mouse click in the chart
      ObjectSetInteger(0, rectangleName, OBJPROP_ZORDER, z_order);
      //--- successful execution
   }
   
    
}

void createobj(datetime time, double price, int arrowCode, int direction, color clr, string txt) {
   string objName = "";
   StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price, Digits()), "(", arrowCode,")");
   
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double spread = ask - bid; 
   
   if (direction > 0) {
      price += 2*spread*_Point;
   } else if (direction < 0){
      price -= 2*spread*_Point;
   }
   
   if (ObjectCreate(0,objName, OBJ_ARROW, 0, time, price)) {
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      if( direction > 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      else if (direction < 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
   string objNameDesc = objName + txt;
   if (ObjectCreate(0, objNameDesc, OBJ_TEXT, 0, time, price)) {
      ObjectSetString(0, objNameDesc, OBJPROP_TEXT, " "+txt);
      ObjectSetInteger(0, objNameDesc, OBJPROP_COLOR, clr);
      if( direction > 0)
         ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR, ANCHOR_TOP);
      else if (direction < 0)
         ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
}

//---
//--- Function to delete objects created by createObj
//---
void deleteObj(datetime time, double price, int arrowCode, string txt) {
   // Create the object name using the same format as createobj
   string objName = "";
   StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price, Digits()), "(", arrowCode,")");
   
   // Delete arrow object
   if (ObjectFind(0,objName) != -1) { // Check if the object exist
      ObjectDelete(0,objName);
   }
   
   // Create description object name
   string objNameDesc = objName + txt;
   
   // Delete the text object
   if (ObjectFind(0,objNameDesc) != 1) {  // Check if the object desc exist
      ObjectDelete(0,objNameDesc);
   }
}

//+------------------------------------------------------------------------------+
int swingPoints() {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, rates);
   
   int indexLastH = iBarShift(_Symbol,PERIOD_CURRENT,lastTimeH);
   int indexLastL = iBarShift(_Symbol,PERIOD_CURRENT,lastTimeL);
   int indexPrevH = iBarShift(_Symbol,PERIOD_CURRENT,prevTimeH);
   int indexPrevL = iBarShift(_Symbol,PERIOD_CURRENT,prevTimeL);
   
   // Break of structure
   if (indexLastH > 0 && indexLastL > 0 && indexPrevH > 0 && indexPrevL > 0) {
      // Bullish
      if (
         rates[indexLastL].low > rates[indexPrevL].low &&
         rates[1].close > rates[indexLastH].high && 
         rates[2].close < rates[indexLastH].high
      ) {
         string objname = "SMC BoS" + TimeToString(rates[indexLastH].time);
         if (ObjectFind(0, objname) < 0) {
            ObjectCreate(0, objname, OBJ_TREND, 0, rates[indexLastH].time, rates[indexLastH].high, rates[1].time, rates[indexLastH].high);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, clrBlue);
            ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
            createobj(rates[indexLastH].time, rates[indexLastH].high, 0, 1,clrBlue, "BoS");
         }
      }
      
      // Bearish
      if (
         rates[indexLastH].high > rates[indexPrevH].high &&
         rates[1].close < rates[indexLastL].low && 
         rates[2].close > rates[indexLastL].low
      ) {
         string objname = "SMC BoS" + TimeToString(rates[indexLastL].time);
         if (ObjectFind(0, objname) < 0) {
            ObjectCreate(0, objname, OBJ_TREND, 0, rates[indexLastL].time, rates[indexLastL].low, rates[1].time, rates[indexLastL].low);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
            createobj(rates[indexLastL].time, rates[indexLastL].low, 0, 1,clrRed, "BoS");
         }
      }
   }
   
   // Change of Character
   if (indexLastH > 0 && indexLastL > 0 && indexPrevH > 0 && indexPrevL > 0) {
      // Bullish
      if (
         rates[indexLastH].high < rates[indexPrevH].high && rates[indexLastL].low < rates[indexPrevL].low &&
         rates[1].close > rates[indexLastH].high && 
         rates[2].close < rates[indexLastH].high
      ) {
         string objname = "SMC CHoCH" + TimeToString(rates[indexLastH].time);
         if (ObjectFind(0, objname) < 0) {
            ObjectCreate(0, objname, OBJ_TREND, 0, rates[indexLastH].time, rates[indexLastH].high, rates[1].time, rates[indexLastH].high);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, clrGreenYellow);
            ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
            createobj(rates[indexLastH].time, rates[indexLastH].high, 0, 1,clrGreenYellow, "CHoCH");
         }
      }
      
      // Bearish
      if (
         rates[indexLastH].high > rates[indexPrevH].high && rates[indexLastL].low > rates[indexPrevL].low &&
         rates[1].close < rates[indexLastL].low && 
         rates[2].close > rates[indexLastL].low
      ) {
         string objname = "SMC CHoCH" + TimeToString(rates[indexLastL].time);
         if (ObjectFind(0, objname) < 0) {
            ObjectCreate(0, objname, OBJ_TREND, 0, rates[indexLastL].time, rates[indexLastL].low, rates[1].time, rates[indexLastL].low);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, clrLightPink);
            ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
            createobj(rates[indexLastL].time, rates[indexLastL].low, 0, 1,clrLightPink, "CHoCH");
         }
      }
   
   }
   
   // swing Detection
   // Swing High
   if (rates[2].high > rates[3].high && rates[2].high > rates[1].high) {
      
      double highvalue = rates[2].high;
      datetime hightime = rates[2].time;
      
      if (LastSwingMeter < 0 && highvalue < Highs[0]) {
         return 0;
      }
      
      if (LastSwingMeter < 0 && highvalue > Highs[0]) {
         deleteObj(HighsTime[0], Highs[0], 234, "");
         ArrayRemove(Highs, 0, 1);
         ArrayRemove(HighsTime, 0, 1);
         
         // Store hightvalue in Highs[]
         // shift existing elements in Highs[] to make space for the new value
         ArrayResize(Highs, MathMin(ArraySize(Highs) + 1, 10));
         for(int i = ArraySize(Highs) - 1; i > 0; i--) {
            Highs[i] = Highs[i-1];   
         }
         // Store highvalue in Highs[0], the first position
         Highs[0] = highvalue;
         
         // Store hightime in HighsTime[]
         // shift existing elements in HighsTime[] to make space for the new value
         ArrayResize(HighsTime, MathMin(ArraySize(HighsTime) + 1, 10));
         for(int i = ArraySize(HighsTime) - 1; i > 0; i--) {
            HighsTime[i] = HighsTime[i-1];   
         }
         // Store hightime in HighsTime[0], the first position
         HighsTime[0] = hightime;
        
         prevTimeH = lastTimeH;
         lastTimeH = hightime;
         
         LastSwingMeter = -1;
         createobj(rates[2].time, rates[2].high, 234, -1, clrGreen, "");
         return -1;
      }
      
      if (LastSwingMeter >= 0) {
         // Store hightvalue in Highs[]
         // shift existing elements in Highs[] to make space for the new value
         ArrayResize(Highs, MathMin(ArraySize(Highs) + 1, 10));
         for(int i = ArraySize(Highs) - 1; i > 0; i--) {
            Highs[i] = Highs[i-1];   
         }
         // Store highvalue in Highs[0], the first position
         Highs[0] = highvalue;
         
         // Store hightime in HighsTime[]
         // shift existing elements in HighsTime[] to make space for the new value
         ArrayResize(HighsTime, MathMin(ArraySize(HighsTime) + 1, 10));
         for(int i = ArraySize(HighsTime) - 1; i > 0; i--) {
            HighsTime[i] = HighsTime[i-1];   
         }
         // Store hightime in HighsTime[0], the first position
         HighsTime[0] = hightime;
         
         prevTimeH = lastTimeH;
         lastTimeH = hightime;
         
         
         LastSwingMeter = -1;
         createobj(rates[2].time, rates[2].high, 234, -1, clrGreen, "");
         return -1;
      }
      
   }
   
   
   
   // Swing Low
   if (rates[2].low < rates[3].low && rates[2].low < rates[1].low) {
      double lowvalue = rates[2].low;
      datetime lowtime = rates[2].time;
      
      if (LastSwingMeter > 0 && lowvalue > Lows[0]) {
         return 0;
      }
      
      if (LastSwingMeter > 0 && lowvalue < Lows[0]) {
         deleteObj(LowsTime[0], Lows[0], 233, "");
         ArrayRemove(Lows, 0, 1);
         ArrayRemove(LowsTime, 0, 1);
         
         // Store lowvalue in Lows[]
         // shift existing elements in Lows[] to make space for the new value
         ArrayResize(Lows, MathMin(ArraySize(Lows) + 1, 10));
         for(int i = ArraySize(Lows) - 1; i > 0; i--) {
            Lows[i] = Lows[i-1];   
         }
         // Store lowvalue in Lows[0], the first position
         Lows[0] = lowvalue;
         
         // Store lowtime in LowsTime[]
         // shift existing elements in LowsTime[] to make space for the new value
         ArrayResize(LowsTime, MathMin(ArraySize(LowsTime) + 1, 10));
         for(int i = ArraySize(LowsTime) - 1; i > 0; i--) {
            LowsTime[i] = LowsTime[i-1];   
         }
         // Store lowtime in LowsTime[0], the first position
         LowsTime[0] = lowtime;
         
         
         prevTimeL = lastTimeL;
         lastTimeL = lowtime;
         
         LastSwingMeter = 1;
         createobj(rates[2].time, rates[2].low, 233, 1, clrDarkOrange, "");
         return 1;
      }
      
      if (LastSwingMeter <= 0) {
         // Store lowvalue in Lows[]
         // shift existing elements in Lows[] to make space for the new value
         ArrayResize(Lows, MathMin(ArraySize(Lows) + 1, 10));
         for(int i = ArraySize(Lows) - 1; i > 0; i--) {
            Lows[i] = Lows[i-1];   
         }
         // Store lowvalue in Lows[0], the first position
         Lows[0] = lowvalue;
         
         // Store lowtime in LowsTime[]
         // shift existing elements in LowsTime[] to make space for the new value
         ArrayResize(LowsTime, MathMin(ArraySize(LowsTime) + 1, 10));
         for(int i = ArraySize(LowsTime) - 1; i > 0; i--) {
            LowsTime[i] = LowsTime[i-1];   
         }
         // Store lowtime in LowsTime[0], the first position
         LowsTime[0] = lowtime;
         
         prevTimeL = lastTimeL;
         lastTimeL = lowtime;
         
         LastSwingMeter = 1;
         createobj(rates[2].time, rates[2].low, 233, 1, clrDarkOrange, "");
         return 1;
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------------------+
int FVG() {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, rates);
   
   
   //--- Bullish FVG
   if (
      rates[1].low > rates[3].high && 
      rates[2].close > rates[3].high && 
      rates[1].close > rates[1].open && 
      rates[3].close > rates[3].open
      ) {
      
      double fvghigh = rates[3].high;
      double fvglow = rates[1].low;
      double fvgtime = rates[0].time;
      
      // Store fvghigh in BuFVGHighs[]
      // shift existing elements in BuFVGHighs[] to make space for the new value
      ArrayResize(BuFVGHighs, MathMin(ArraySize(BuFVGHighs) + 1, 10));
      for(int i = ArraySize(BuFVGHighs) - 1; i > 0; i--) {
         BuFVGHighs[i] = BuFVGHighs[i-1];   
      }
      // Store fvghigh in BuFVGHighs[0], the first position
      BuFVGHighs[0] = fvghigh;
      
      // Store fvglow in BuFVGLows[]
      // shift existing elements in BuFVGLows[] to make space for the new value
      ArrayResize(BuFVGLows, MathMin(ArraySize(BuFVGLows) + 1, 10));
      for(int i = ArraySize(BuFVGLows) - 1; i > 0; i--) {
         BuFVGLows[i] = BuFVGLows[i-1];   
      }
      // Store fvglow in BuFVGLows[0], the first position
      BuFVGLows[0] = fvglow;
      
      // Store fvgtime in BuFVGTime[]
      // shift existing elements in BuFVGTime[] to make space for the new value
      ArrayResize(BuFVGTime, MathMin(ArraySize(BuFVGTime) + 1, 10));
      for(int i = ArraySize(BuFVGTime) - 1; i > 0; i--) {
         BuFVGTime[i] = BuFVGTime[i-1];   
      }
      // Store fvgtime in BuFVGTime[0], the first position
      BuFVGTime[0] = fvgtime;
      
      createRect(0, "Bullish FVG", 0, rates[3].time, rates[3].high, rates[0].time, rates[1].low, clrGreen, 1, "B.FVG", STYLE_SOLID, 1, false,false, true, false);
      return 1;
   }
   
   
   //--- Bearish FVG
   if (
      rates[1].high < rates[3].low && 
      rates[2].close < rates[3].low && 
      rates[1].close < rates[1].open && 
      rates[3].close < rates[3].open
      ) {
      double fvghigh = rates[3].low;
      double fvglow = rates[1].high;
      double fvgtime = rates[0].time;

      // Store fvghigh in BeFVGHighs[]
      // shift existing elements in BeFVGHighs[] to make space for the new value
      ArrayResize(BeFVGHighs, MathMin(ArraySize(BeFVGHighs) + 1, 10));
      for(int i = ArraySize(BeFVGHighs) - 1; i > 0; i--) {
         BeFVGHighs[i] = BeFVGHighs[i-1];   
      }
      // Store fvghigh in BeFVGHighs[0], the first position
      BeFVGHighs[0] = fvghigh;
      
      // Store fvglow in BeFVGLows[]
      // shift existing elements in BeFVGLows[] to make space for the new value
      ArrayResize(BeFVGLows, MathMin(ArraySize(BeFVGLows) + 1, 10));
      for(int i = ArraySize(BeFVGLows) - 1; i > 0; i--) {
         BeFVGLows[i] = BeFVGLows[i-1];   
      }
      // Store fvglow in BeFVGLows[0], the first position
      BeFVGLows[0] = fvglow;
      
      // Store fvgtime in BeFVGTime[]
      // shift existing elements in BeFVGTime[] to make space for the new value
      ArrayResize(BeFVGTime, MathMin(ArraySize(BeFVGTime) + 1, 10));
      for(int i = ArraySize(BeFVGTime) - 1; i > 0; i--) {
         BeFVGTime[i] = BeFVGTime[i-1];   
      }
      // Store fvgtime in BeFVGTime[0], the first position
      BeFVGTime[0] = fvgtime;
      
      createRect(0, "Bearish FVG", 0, rates[3].time, rates[3].low, rates[0].time, rates[1].high, clrRed, 1, "S.FVG", STYLE_SOLID, 1, false,false, true, false);
      return -1;
   }
   return 0;
}