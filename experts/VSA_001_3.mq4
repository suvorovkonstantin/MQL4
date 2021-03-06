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
input bool use_trand = true; //трендоориентированость
input bool reverse = true; //учитывать разворотный бар
input int secret= 2; //;) 
input int ma_period= 1; //;)

double upper_fractal;   
double lower_fractal;

struct ZZPick
{
   double price;
   double time;
   ZZPick()
   {
      price=0;
      time=0;
   }
};

ZZPick picks[9];

enum trend_mode
{
 UP,
 DOWN,
 BROKEN,
 NONE
};

void CloseAllOrders(int type);
bool is_equal(MqlRates& b1,MqlRates& b2);
void Writer();
//zigzag_trend_mode ZZTrand(string symbol, int timeframe);
int DrawArrow(int CodeArrow,color ColorArrow,int i,int TypeArrow);


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
   bool new_fracUP = false;   
   bool new_fracLOW = false;
     
   datetime expiration = 0;   
   if(expiration_bar!=0)
      expiration=TimeCurrent()+expiration_bar*PeriodSeconds(Period());
   
   int trand = 0;   
   //double ma_trand1 = NormalizeDouble(iMA(Symbol(),0,ma_period,0,1,0,0),5);
   //double ma_trand2 = NormalizeDouble(iMA(Symbol(),0,ma_period,0,1,0,1),5);

   //trand = acd_trand();
   if(!is_equal(g_ready_bar,rates[1]))
   {
      g_ready_bar=rates[1];


       
   trend_mode tmp = acd_trand();
      
   if(tmp==DOWN && use_trand)
      trand = 1;
   if(tmp==UP && use_trand)
      trand = 2;         

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
      double ma_range = iCustom(NULL,0,"BetterVolume 1.4",6,1);
   
      for(int n=1; n<(Bars);n++)
         if((iFractals(NULL,0,MODE_UPPER,n)!=NULL))
         {
            if(upper_fractal==iFractals(NULL,0,MODE_UPPER,n))
               break;
            upper_fractal = iFractals(NULL,0,MODE_UPPER,n); 
            new_fracUP = true;    
            break;
         }
         
        
      for(int n=1; n<(Bars);n++)
         if(iFractals(NULL,0,MODE_LOWER,n)!=NULL)
         {
            if(lower_fractal==iFractals(NULL,0,MODE_LOWER,n))
               break;
            lower_fractal = iFractals(NULL,0,MODE_LOWER,n);
            new_fracLOW = true;
            break;
         }

     
      for (int i=0; i<OrdersTotal(); i++)       
         if(OrderSelect(i,SELECT_BY_POS)==true)            
         {
            if((OrderType() == OP_SELL)&&new_fracUP)
                     mod_ticket = OrderModify(OrderTicket(),OrderOpenPrice(), NormalizeDouble((OrderStopLoss()+upper_fractal)/2,Digits),OrderTakeProfit(),0,Blue); 
            if((OrderType() == OP_BUY)&&new_fracLOW)
                     mod_ticket = OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble((OrderStopLoss()+lower_fractal)/2,Digits) ,OrderTakeProfit(),0,Red);             
         }      

      if (red==0 && blue==0 && yellow!=0 && green==0 && white==0 && magenta==0) // спред
      {
             
      }
   
      if (red==0 && blue==0 && yellow==0 && green!=0 && white==0 && magenta==0 && reverse) // разворот
      {         
         for (int i=0; i<OrdersTotal(); i++)
         {
            if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
               continue;
            if((OrderType() == OP_SELL)&&(Close[2] <= Open[2]))
                     close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_ASK),Digits), g_slippage, Blue);
            if((OrderType() == OP_BUY)&&(Close[2] >= Open[2]))
                     close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_BID),Digits), g_slippage, Red); 
         }
      }    

      if ((red!=0 && blue==0 && yellow==0 && green==0 && white==0 && magenta==0 )&&(trand != 1)) // бычий тренд
      {      
         if(OrdersTotal()==0)
         {
            OrderSend(Symbol(),OP_BUYSTOP,g_lot,price_buy,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);
               //ticket=OrderSend(Symbol(),OP_BUY,g_lot,Bid,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);            
         }
         else
         {
            for (int i=0; i<OrdersTotal(); i++)
            {
               if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                  continue;
               switch (OrderType())
                  {
                     case OP_SELL:   
                     {
                        close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_ASK),Digits), g_slippage, Blue);
                        OrderSend(Symbol(),OP_BUYSTOP,g_lot,price_buy,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);
                         //  ticket=OrderSend(Symbol(),OP_BUY,g_lot,Bid,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);   
                     }
                     case OP_SELLSTOP: 
                     {
                        close_ticket = OrderDelete(OrderTicket(),Blue);
                        OrderSend(Symbol(),OP_BUYSTOP,g_lot,price_buy,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);
                           //ticket=OrderSend(Symbol(),OP_BUY,g_lot,Bid,g_slippage,sl_buy,tp_buy,"Bull",magic_number,expiration,clrGreen);
                     }                     
                  }
            }
         }
      }

         
      if ((white!=0 && blue==0 && yellow==0 && green==0 && red==0 && magenta==0)&&(trand != 2)) // медвежий тренд
      {
         if(OrdersTotal()==0)
         {
            OrderSend(Symbol(),OP_SELLSTOP,g_lot,price_sell,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);
             //  ticket=OrderSend(Symbol(),OP_SELL,g_lot,Ask,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);            
         }
         else
         {
            for (int i=0; i<OrdersTotal(); i++)
            {
               if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                  continue;
               switch (OrderType())
                  {
                     case OP_BUY:   
                     {
                        close_ticket = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(MarketInfo(Symbol(),MODE_BID),Digits), g_slippage, Red);
                        OrderSend(Symbol(),OP_SELLSTOP,g_lot,price_sell,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);
                           //ticket=OrderSend(Symbol(),OP_SELL,g_lot,Ask,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);   
                     }
                     case OP_BUYSTOP: 
                     {
                        close_ticket = OrderDelete(OrderTicket(),Red);
                        OrderSend(Symbol(),OP_SELLSTOP,g_lot,price_sell,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);
                        //   ticket=OrderSend(Symbol(),OP_SELL,g_lot,Ask,g_slippage,sl_sell,tp_sell,"Bear",magic_number,expiration,clrRed);
                     }                     
                  }
            }
         }
      }
      
      double price = price_buy;
      double sl = sl_buy;
      string type;
      switch (OrderType())
      {
         case OP_BUY     :   type = "BUY";
         case OP_BUYSTOP :   type = "BUYSTOP";
         case OP_SELL    :   type = "SELL";
         case OP_SELLSTOP:   type = "SELLSTOP";
      }
      
      if(ticket<0)
      {
         int err=GetLastError();  
         string err_msg= type+ ":" + "\n"
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

int DrawLine(string name,double price)
{
   int rnd = rand();
   Comment(price);
   ObjectCreate(name,OBJ_HLINE,0,0,price); 
   ObjectSet(name,6, Pink);
   return(0);
}

trend_mode ZZTrand(string symbol, int timeframe)
{
   MqlRates rates[];
   ArrayCopyRates(rates,NULL,0);
   int count_picks = 0;
   
   trend_mode zz_bear = NONE;
   trend_mode zz_bull = NONE;
   trend_mode zz = NONE;
   
   double tmp;
   for(int i=2;i<10000;i++)
       {
         tmp=iFractals(NULL,0,0,i);

         if(tmp!=0)
            {
               picks[count_picks].price = tmp;
               picks[count_picks].time = rates[i].time;
               count_picks++;
               if(count_picks==9)break;
            }
      } 
      /*
   for(int i=0;i<3;i++)
         DrawLine("pick " + IntegerToString(i+1)+ " " + rand(),picks[i].price);*/
   /*         
   double tg1 = (picks[0].price - picks[1].price)/MarketInfo(NULL,MODE_POINT)/((picks[0].time - picks[1].time)/PeriodSeconds());
   double tg2 = (picks[1].price - picks[2].price)/MarketInfo(NULL,MODE_POINT)/((picks[1].time - picks[2].time)/PeriodSeconds());
   double tg3 = (picks[2].price - picks[3].price)/MarketInfo(NULL,MODE_POINT)/((picks[2].time - picks[3].time)/PeriodSeconds());
   double tg4 = (picks[3].price - picks[4].price)/MarketInfo(NULL,MODE_POINT)/((picks[3].time - picks[4].time)/PeriodSeconds());
   double tg5 = (picks[4].price - picks[5].price)/MarketInfo(NULL,MODE_POINT)/((picks[4].time - picks[5].time)/PeriodSeconds());

   if(tg1<0)
      if(tg1>tg3 && tg4>tg2) zz = ZZ_DOWN;
      if(tg1<tg3 && tg4<tg2) zz = ZZ_UP;
   if(tg1>0)
      if(tg1>tg3 && tg4>tg2) zz = ZZ_UP;
      if(tg1<tg3 && tg4<tg2) zz = ZZ_DOWN;
    */  
   Comment("");
   //Comment(((picks[0].time - picks[1].time)/PeriodSeconds())," ",((picks[1].time - picks[2].time)/PeriodSeconds())," ",((picks[2].time - picks[3].time)/PeriodSeconds())," ",((picks[3].time - picks[4].time)/PeriodSeconds()));
   Comment((picks[0].price - picks[1].price)/MarketInfo(NULL,MODE_POINT));
   //Comment(tg4," ",tg3," ",tg2," ",tg1);
   //Comment(EnumToString(zz));
   
   
   return zz;
   }

int DrawArrow(int CodeArrow,color ColorArrow,int i,int TypeArrow) 
{
   if(i<=0)
   return -1;
   
   string nm=IntegerToString(GetTickCount());
   
   if(ObjectFind(nm)>0)
   nm=nm+"1";
   
   if(ObjectFind(nm)<0) 
   {
   if(TypeArrow==0) 
   ObjectCreate(nm,22,0,iTime(NULL,0,i),iHigh(NULL,0,i)+0.0004);// стрелка вверх над баром
   else 
   ObjectCreate(nm,22,0,iTime(NULL,0,i),iLow(NULL,0,i)-0.0001);// стрелка вниз под баром
   }
   
   ObjectSet(nm,OBJPROP_ARROWCODE,CodeArrow);
   ObjectSet(nm,OBJPROP_COLOR,ColorArrow);
   
   return 0;
}
/*

*/
//+------------------------------------------------------------------+
trend_mode acd_trand()
{

   double acd_pivot_poit = iCustom(NULL,0,"ACD","00:30","00:30",true,true,false,0,0);
   /*double acd_range_top = iCustom(NULL,0,"ACD","00:30","00:30",true,true,false,1,0);
   double acd_range_bottom = iCustom(NULL,0,"ACD","00:30","00:30",true,true,false,2,0);
   double acd_day_high = iCustom(NULL,0,"ACD","00:30","00:30",true,true,false,3,0);
   double acd_day_low = iCustom(NULL,0,"ACD","00:30","00:30",true,true,false,4,0);
  */ 
   if(Ask > acd_pivot_poit)
      return UP;
   if(Bid < acd_pivot_poit)
      return DOWN;
   
   //Comment(acd_line_1 + " " +acd_line_2 + " " +acd_line_3 + " " +acd_line_4 + " " +acd_line_5 + " " +acd_line_6 + " " +acd_line_7);
   
   return NONE;
}