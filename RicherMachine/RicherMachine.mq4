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

//MARK: Constant
int limit=4;

//MARK: Storage
int tradeDate=0;
double iBandUpper,iBandLower;
int runningOrder=1;
int orderBuy,orderSell;
int orderOpenedTicket;
double buyStartPrice,sellStartPrice;
double fiboMid;
double fiboUpper1,fiboUpper2,fiboUpper3;
double fiboLower1,fiboLower2,fiboLower3;
int fiboLastActive=4;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
// Init
   iBandUpper=iBands(_Symbol,
                     _Period,
                     iBandPeriod,
                     iBandDeviations,
                     iBandShift,
                     PRICE_CLOSE,
                     MODE_UPPER,
                     1);
   iBandLower=iBands(_Symbol,
                     _Period,
                     iBandPeriod,
                     iBandDeviations,
                     iBandShift,
                     PRICE_CLOSE,
                     MODE_LOWER,
                     1);
   resetTradeDate();

//RMOrder test[4];
//Print("RMOrders", ArrayResize(test));

// Event 1: Start pending 
   if(tradeDate==0 && Close[1]>iBandUpper)
     {
      fiboMid=Bid;
      fiboUpper1=Bid+(fiboWidth*Point);
      fiboUpper2=Bid+((fiboWidth*Point)*2);
      fiboUpper3=Bid+((fiboWidth*Point)*3);
      fiboLower1=Bid-(fiboWidth*Point);
      fiboLower2=Bid-((fiboWidth*Point)*2);
      fiboLower3=Bid-((fiboWidth*Point)*3);
      fiboLastActive=4;
      orderBuy=loopOrderSend(Symbol(),
                             OP_BUYSTOP,
                             currentLots(),
                             getFiboByLastActive(fiboLastActive-1),
                             slippage,
                             getFiboByLastActive(fiboLastActive),
                             getFiboByLastActive(fiboLastActive-2),
                             iBandUpper,
                             0,
                             0,
                             DodgerBlue);
      orderSell=loopOrderSend(Symbol(),
                              OP_SELLSTOP,
                              currentLots(),
                              getFiboByLastActive(fiboLastActive+1),
                              slippage,
                              getFiboByLastActive(fiboLastActive),
                              getFiboByLastActive(fiboLastActive+2),
                              iBandLower,
                              0,
                              0,
                              DeepPink);
      tradeDate=TimeDay(TimeCurrent());
      runningOrder+=1;
      clearStorage();
      return(0);
     }

// Event 2: Decision to delete pending order
   if(orderOpenedTicket==NULL)
     {

     }
   for(int n=OrdersTotal()-1; n>=0; n--)
     {
      if(!OrderSelect(n,SELECT_BY_POS))
        {
         logError("OrderSelect()",GetLastError());
         continue;
        }
      if(OrderType()==OP_BUY && orderSell!=NULL)
        {
         orderOpenedTicket=OrderTicket();
         loopOrderDelete(orderSell);
         orderSell=NULL;
         fiboLastActive-=1;
         break;
        }
      else if(OrderType()==OP_SELL && orderBuy!=NULL)
        {
         orderOpenedTicket=OrderTicket();
         loopOrderDelete(orderBuy);
         orderBuy=NULL;
         fiboLastActive+=1;
         break;
        }
     }

// Event 3: Check order close
   if(OrdersHistoryTotal()>0 && OrderSelect(orderOpenedTicket,SELECT_BY_TICKET,MODE_HISTORY) && orderOpenedTicket!=NULL)
     {
      if(StringFind(OrderComment(),"[sl]")>=0)
           {
            if(OrderType()==OP_SELL)
              {
               orderBuy=loopOrderSend(Symbol(),
                                      OP_BUY,
                                      currentLots(),
                                      getFiboByLastActive(fiboLastActive-1),
                                      slippage,
                                      getFiboByLastActive(fiboLastActive),
                                      getFiboByLastActive(fiboLastActive-2),
                                      iBandUpper,
                                      0,
                                      0,
                                      DodgerBlue);
               orderSell=NULL;
               fiboLastActive-=1;
              }
            else if(OrderType()==OP_BUY)
              {
               orderSell=loopOrderSend(Symbol(),
                                       OP_SELL,
                                       currentLots(),
                                       getFiboByLastActive(fiboLastActive+1),
                                       slippage,
                                       getFiboByLastActive(fiboLastActive),
                                       getFiboByLastActive(fiboLastActive+2),
                                       iBandLower,
                                       0,
                                       0,
                                       DeepPink);
               orderBuy=NULL;
               fiboLastActive+=1;
              }
            runningOrder+=1;
            //Set Ticket
            orderOpenedTicket=NULL;
           }
         if(StringFind(OrderComment(),"[tp]")>=0)
           {
            runningOrder-=1;
            orderOpenedTicket=NULL;
           }
     }
   clearStorage();
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getFiboByLastActive(int fibo)
  {
   double value;
   switch(fibo)
     {
      case 1:
         value=fiboUpper3;
         break;
      case 2:
         value=fiboUpper2;
         break;
      case 3:
         value=fiboUpper1;
         break;
      case 4:
         value=fiboMid;
         break;
      case 5:
         value=fiboLower1;
         break;
      case 6:
         value=fiboLower2;
         break;
      case 7:
         value=fiboLower3;
         break;
      default:
         value=0;
         break;
     }
   return value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int loopOrderSend(
                  string symbol,
                  int cmd,
                  double volume,
                  double price,
                  int sp,
                  double stoploss,
                  double takeprofit,
                  string comment=NULL,
                  int magic=0,
                  datetime expiration=0,
                  color arrow_color=clrNONE
                  )
  {
   int isSended=0;
   while(!isSended)
     {
      isSended=OrderSend(symbol,cmd,volume,price,sp,stoploss,takeprofit,comment,0,0,arrow_color);
      if(isSended)
        {
         return isSended;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void loopOrderDelete(int order)
  {
   int isDeleted=0;
   while(!isDeleted)
     {
      isDeleted=OrderDelete(order);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
void clearStorage()
  {
// Clear ???
   buyStartPrice=NULL;
   sellStartPrice=NULL;
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double currentLots()
  {
   return lots * runningOrder;
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
