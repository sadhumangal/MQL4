//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012,  CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+



// Note
// OrderSend(Currency, TradeType, lots, StartPrice, slipage, stoploss, takeprofit, comment, magic, expiration, arrow_color)



// iBandPeriod - range of candle
// iBandDeviations -
// iBandShift - shift from period
// fiboWidth - fibo width
// lots - lots
// slippage - accept value to init trade,  pip
extern int iBandPeriod=20;
extern double iBandDeviations=2;
extern int iBandShift=0;
extern double fiboWidth=100;
extern double lots=0.1;
extern int slippage=3;

// isTrade - 
// totalOrder -
// orderBuy -
// orderSell -
// price - point
int tradeDate=0;
int totalOrder;
int orderBuy,orderSell;
double iBandUpper,iBandLower;
int running=0;
int limit=3;

int orderOpenedTicket;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
// Init
   totalOrder = OrdersTotal();
   iBandUpper = iBands(_Symbol, _Period, iBandPeriod, iBandDeviations, iBandShift, PRICE_CLOSE, MODE_UPPER, 1);
   iBandLower = iBands(_Symbol, _Period, iBandPeriod, iBandDeviations, iBandShift, PRICE_CLOSE, MODE_LOWER, 1);
   resetTradeDate();

// Event 1: Start pending 
   if(tradeDate==0 && Close[1]>iBandUpper)
     {
      double buyStop=Ask+fiboWidth*Point;
      double sellStop=Bid-fiboWidth*Point;
      orderBuy=OrderSend(Symbol(),OP_BUYSTOP,lots,buyStop,slippage,buyStop -(fiboWidth*Point),buyStop+(fiboWidth*Point),iBandUpper,0,0,DodgerBlue);
      orderSell=OrderSend(Symbol(),OP_SELLSTOP,lots,sellStop,slippage,sellStop+(fiboWidth*Point),sellStop -(fiboWidth*Point),iBandLower,0,0,DeepPink);
      tradeDate=TimeDay(TimeCurrent());
      return(0);
     }

// Event 2: Decision to delete pending order
   for(int n=OrdersTotal()-1; n>=0; n--)
     {
      if(OrderSelect(n,SELECT_BY_POS))
        {
         if(OrderType()==OP_BUY && orderSell!=NULL)
           {
            orderOpenedTicket=OrderTicket();
            
            OrderDelete(orderSell);
            orderSell=NULL;
            break;
           }
         else if(OrderType()==OP_SELL && orderBuy!=NULL)
           {
            orderOpenedTicket=OrderTicket();
            OrderDelete(orderBuy);
            orderBuy=NULL;
            break;
           }
           } else {
         logError("OrderSelect()",GetLastError());
        }
     }

// Event 3: Check order close
   if(OrdersHistoryTotal()>0)
     {
      if(OrderSelect(orderOpenedTicket,SELECT_BY_TICKET,MODE_HISTORY))
        {
         if(OrderProfit()<0 && orderOpenedTicket!=NULL) 
           {
            Print("Stop loss at",orderOpenedTicket);
            orderOpenedTicket = NULL;
           }
        }
     }




   return(0);
  }
//+------------------------------------------------------------------+

void resetTradeDate()
  {
   if(tradeDate!=TimeDay(TimeCurrent()))
     {
      tradeDate=0;
     }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void logEvent(string message)
  {
   Print("----------Event----------: ",message);
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void logError(string message,int lastError)
  {
   Print("Error: ",message,"LastError: ",lastError);
   return;
  }
//+------------------------------------------------------------------+
