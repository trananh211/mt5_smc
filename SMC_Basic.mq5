//+------------------------------------------------------------------+
//|                                                    SMC_Basic.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
                  const ENUM_LINE_STYLE      style = STYLE_SOLID,
                  const    int               width=1;
                  const    bool              fill=false,
                  const    bool              back=false,
                  const    bool              selection= true,
                  const    bool              hidden=true,
                  const    long              z_order=0       
) {
   
}

void createobj(datetime time, double price, int arrowCode, int direction, color clr, string txt) {
   string objName = "";
   StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price, Digits()), "(", arrowCode,")");
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = ask - bid; 
   
   if (direction > 0) {
      price += 2*spread*_Point;
   } else if (direction < 0){
      price -= 2*spread*_Point;
   }
   
   if (ObjectCreate(0,objName, OBJ_ARROW, 0, time, price)) {
      ObjectSetInteger(0,objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      if( direction > 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      else if (direction < 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
   string objNameDesc = objName + txt;
   if (ObjectCreate(0, objNameDesc, OBJ_TEXT,0, time, price)) {
      ObjectSetInteger(0, objNameDesc, OBJPROP_TEXT, " "+txt);
      ObjectSetInteger(0, objNameDesc, OBJPROP_COLOR, clr);
      if( direction > 0)
         ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR, ANCHOR_TOP);
      else if (direction < 0)
         ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
}

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
