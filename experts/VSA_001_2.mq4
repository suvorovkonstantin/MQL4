//+------------------------------------------------------------------+
//|                                                    VSA_001_0.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#include "ax_bar_utils.mqh"

MqlRates g_ready_bar;


input double g_lot=0.01;//лот
input int magic_number = 1488; //магик
input int g_slippage = 3;//проскальзывание
input int expiration_bar = 3;//экспирация
input int g_delta_points_sl=1; //дельта стоп-лосса
input int g_delta_points_p=1; //дельта отложености  
input int tp= 0; //фиксированая прибыль 

void CloseAllOrders(int type);
bool is_equal(MqlRates& b1,MqlRates& b2);
void Writer();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MqlRates rates[];
   ArrayCopyRates(rates,NULL,0);
   g_ready_bar=rates[1];  
   
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
    MqlRates rates[];
    ArrayCopyRates(rates,NULL,0);
       
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   
   double sl_buy= 0; 
   double sl_sell= 0;
   double price_buy= 0;
   double price_sell= 0;
   double tp_sell = 0;
   double tp_buy = 0;
   double sl_sell_mod = 0;   
   double sl_buy_mod = 0;
   
   int ticket=-1;
   int close_ticket = -1;
   int mod_ticket = -1;
   
   datetime expiration = 0;   
   if(expiration_bar!=0)
      expiration=TimeCurrent()+expiration_bar*PeriodSeconds(Period());

   if(!is_equal(g_ready_bar,rates[1]))
   {
      g_ready_bar=rates[1];
      
      price_buy  = MathMax(NormalizeDouble(Ask+minstoplevel*Point,Digits),NormalizeDouble(High[1]+g_delta_points_p*Point,Digits));
      price_sell = MathMin(NormalizeDouble(Bid-minstoplevel*Point,Digits),NormalizeDouble(Low[1]-g_delta_points_p*Point,Digits));
      sl_buy = MathMin(NormalizeDouble(MarketInfo(Symbol(),MODE_BID)-minstoplevel*Point,Digits),NormalizeDouble(Low[1] - g_delta_points_sl*Point,Digits));
      sl_sell= MathMax(NormalizeDouble(High[1] + g_delta_points_sl*Point,Digits),NormalizeDouble(MarketInfo(Symbol(),MODE_ASK)+minstoplevel*Point,Digits)); 
     
      if (tp != 0)
      {
         tp_sell=NormalizeDouble(price_sell - tp*Point,Digits);
         tp_buy=NormalizeDouble(price_buy + tp*Point,Digits);         
      }
      
      double red     = iCustom(NULL,0,"BetterVolume 1.4",0,1);
      double blue    = iCustom(NULL,0,"BetterVolume 1.4",1,1);
      double yellow  = iCustom(NULL,0,"BetterVolume 1.4",2,1);
      double green   = iCustom(NULL,0,"BetterVolume 1.4",3,1);
      double white   = iCustom(NULL,0,"BetterVolume 1.4",4,1);
      double magenta = iCustom(NULL,0,"BetterVolume 1.4",5,1); 
      
      for(int n=0; n<(Bars-1);n++)
         if(iFractals(NULL,0,MODE_UPPER,n)!=NULL)
         {
            sl_sell_mod = NormalizeDouble(iFractals(NULL,0,MODE_UPPER,n) + g_delta_points_sl*Point,Digits); 
            break;
         }   
      for(int n=0; n<(Bars-1);n++)
         if(iFractals(NULL,0,MODE_LOWER,n)!=NULL)
         {
            sl_buy_mod = NormalizeDouble(iFractals(NULL,0,MODE_LOWER,n) - g_delta_points_sl*Point,Digits); ; 
            break;
         }
      
      for (int i=1; i<=OrdersTotal(); i++)       //Цикл по всем ордерам,.. //отражённым в терминале
            if(OrderSelect(i-1,SELECT_BY_POS)==true)//Если есть следующий              
               Comment("Orders Count: ",OrderType());
      if(OrdersTotal()!=0)
      {
            if((OrderType() == OP_SELL)&&(sl_sell > sl_sell_mod))
                     mod_ticket = OrderModify(OrderTicket(),OrderOpenPrice(), NormalizeDouble((sl_sell_mod + OrderStopLoss())/2,Digits),OrderTakeProfit(),0,Blue); 
            if((OrderType() == OP_BUY)&&(sl_buy < sl_buy_mod))
                     mod_ticket = OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble((sl_buy_mod + OrderStopLoss())/2,Digits) ,OrderTakeProfit(),0,Red);             
      }         
      
      if (red==0 && blue==0 && yellow!=0 && green==0 && white==0 && magenta==0) // спред
      {
         //CloseThisSymbolAll();    
      }
      if (red==0 && blue==0 && yellow==0 && green!=0 && white==0 && magenta==0) // разворот
      {
         for (int i=1; i<=OrdersTotal(); i++)      //отражённым в терминале
            if(OrderSelect(i-1,SELECT_BY_POS)==true)//Если есть следующий     
               Comment(OrderType());       
         if(OrdersTotal()!=0)
         {
            if((OrderType() == OP_SELL)&&(Close[2] <= Open[2]))
                     close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_ASK),Digits), g_slippage, Blue);
            if((OrderType() == OP_BUY)&&(Close[2] >= Open[2]))
                     close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_BID),Digits), g_slippage, Red); 
         }
      }    
      
      if (red!=0 && blue==0 && yellow==0 && green==0 && white==0 && magenta==0 ) // бычий тренд
      {      
         for (int i=1; i<=OrdersTotal(); i++)       //Цикл по всем ордерам,..   //отражённым в терминале
            if(OrderSelect(i-1,SELECT_BY_POS)==true)//Если есть следующий
               Comment("Orders Count: ",OrderType()); 
               
         if(OrdersTotal()==0)
               ticket=OrderSend(Symbol(),OP_BUYSTOP,g_lot,price_buy,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);
         else
            if((OrderType() == OP_SELLSTOP)||(OrderType() == OP_SELL))
            {
               if(OrderType() == OP_SELLSTOP)
                  close_ticket = OrderDelete(OrderTicket(),Blue);
               //else
               //   close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_ASK),Digits), g_slippage, Blue);
               ticket=OrderSend(Symbol(),OP_BUYSTOP,g_lot,price_buy,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);  
               if (ticket < 0)
                   ticket=OrderSend(Symbol(),OP_BUY,g_lot,Bid,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);         
            }
      }
         
      if (white!=0 && blue==0 && yellow==0 && green==0 && red==0 && magenta==0) // медвежий тренд
      {
         for (int i=1; i<=OrdersTotal(); i++)       //Цикл по всем ордерам,.. //отражённым в терминале
            if(OrderSelect(i-1,SELECT_BY_POS)==true)//Если есть следующий              
               Comment("Orders Count: ",OrderType()); 
          
         if(OrdersTotal()==0)
            ticket=OrderSend(Symbol(),OP_SELLSTOP,g_lot,price_sell,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);
         else
            if((OrderType() == OP_BUYSTOP)||(OrderType() == OP_BUY))
            {      
               if(OrderType() == OP_BUYSTOP)
                  close_ticket = OrderDelete(OrderTicket(),Red);
               //else
               //   close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_BID),Digits), g_slippage, Red); 
               ticket=OrderSend(Symbol(),OP_SELLSTOP,g_lot,price_sell,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed); 
               if (ticket < 0)
                  ticket=OrderSend(Symbol(),OP_SELL,g_lot,Ask,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);    
            }
      }
      
      double price = price_buy;
      double sl = sl_buy;
      
      if(ticket<0)
      {
         int err=GetLastError();  
         string err_msg= OrderType() + "\n"
         " open price:"+DoubleToString( NormalizeDouble(price, Digits))+"\n"+ 
         " sl buy:"+DoubleToString(sl_buy)+"\n"+
         " sl sell:"+DoubleToString(sl_sell)+"\n";
         Print(err_msg);
      }      
   }
}
  
bool is_equal(MqlRates& b1,MqlRates& b2)
{
 return b1.time==b2.time;
}
/*

*/
//+------------------------------------------------------------------+
