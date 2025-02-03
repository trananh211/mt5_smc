//+------------------------------------------------------------------+
//|                                                    SMC_Basic.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

int barsTotal;

double Highs[], Lows[];
datetime HighsTime[], LowsTime[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArraySetAsSeries(Highs, true);
   ArraySetAsSeries(Lows, true);
   ArraySetAsSeries(HighsTime, true);
   ArraySetAsSeries(LowsTime, true);
//---
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
      swingPoints();
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
   // swing Detection
   // Swing High
   if (rates[2].high > rates[3].high && rates[2].high > rates[1].high) {
      createobj(rates[2].time, rates[2].high, 234, -1, clrGreen, "High");
      return -1;
   }
   
   // Swing Low
   if (rates[2].low < rates[3].low && rates[2].low < rates[1].low) {
      createobj(rates[2].time, rates[2].low, 233, 1, clrDarkOrange, "Low");
      return 1;
   }
   
   return 0;
}