
/*
Written by Джон(Jeniacomru)
Based on indicator http://www.forexfactory.com/showthread.php?t=127271) 
*/
#property copyright "eevviill && Максик" 
#property link "itisallillusion@gmail.com"




//--- input parameters
extern double    Lot=0.1;

extern int SL = 3;
extern int TP = 2;

extern int StartHour = 2;
extern int StopHour = 23;

extern string exit = "EXIT settings";
extern bool Exitonchangedot1=false;//Выход при смене dot1
extern bool Exitonchangedot2=true;//Выход при смене dot1

extern string bub = "Безубыток";
extern bool   Bezubitok = True;
extern int    BULevel = 5;
extern int    BUsize = 1;

extern string enter = "ENTER settings";
extern string dot2_ = "Enter when dot2 changed colour last";//Вход возможен если dot2 поменял цвет последним
extern bool Enterdot2changed = true;
extern string dot3_ = "Enter when dot3 changed colour last";//Вход возможен если dot3 поменял цвет последним
extern bool Enterdot3changed = false;
extern string dot2t_ = "2 dots changes togather";//Входим если 2Dots одновременно поменяли цвет
extern bool twodotschangestogather13 = false;
extern bool twodotschangestogather24 = false;
extern bool twodotschangestogather12 = true;
extern bool twodotschangestogather34 = true;
extern string dotignor_ = "Ignor 1 dot for enter";//Игнорирование 1 Dot(одного трикса) для входа
extern bool Ignor1dotforenter = false;
extern string dot34cand_ = "Can enter if same way dot3&4(candels)";//Вход возможен только если dot3 && dot4 одинакового цвета ...свечей
extern int enterifsamewaydot34 = 5;
extern string dot2cand_ = "Can enter if oposite way dot2(candels)";//Вход возможен только если dot имел противоположное направление ...свечей
extern int enterifopositewaydot2 = 8;
extern string candbetw_ = "Min candles between exit and new enter";//Вход возможен только если минимальное количество свеч между прошлым выходом и новым входом
extern int candexitandnewenter = 14;
extern string candbetwdot2_ = "Can enter if dot2 changes in previous candles(between enters)";//Новый вход возможен только если dot2 менял цвет между входами
extern bool candenternewenterdot2 = true;
extern string candtelo_ = "Min change(pips) from previous candle";//Вход возможен только если минимальное количество разницы пунктов между предыдущей и новой свечой для входа (размер тела)
extern int telosize = 3;
extern string maxs_ = "Enters candle length max pips";//Вход возможен только если входная свеча имеет макс величину(пунктов)
extern int maxsize = 13;
extern string mins_ = "Enters candle length min pips";//Вход возможен только если входная свеча имеет мин величину(пунктов)
extern int minsize = 4;
extern string shadow_ = "Enters candle- max lenth of shadow in our way for enter";//Вход возможен только если входная свеча имеет макс величину тени(пунктов) (куда сигнал, туда и тень)
extern int shadow = 2;
extern string candrsi_ = "Min candles for enter from OB/OS(RSI) levels";//Вход возможен только если минимальное растояние(свечей) от конца OB/OS до входа
extern int mincandlesRSI = 9;
extern string nearMA_ = "Not trade near MA pips";//Вход возможен только если цена не ближе ...пунктов от МА
extern int nearMA = 8;
extern int period_MA = 60;
extern bool nearHighLow = false;//true - Вход возможен только если количество пунктов от цены к мин\макс дня не превышает...                             //false - наоборот...
extern int PipsnearHighLow = 8;

extern string rsi_ = "RSI settings";
extern int periodRSI = 5;
extern int applied_priceRSI = PRICE_CLOSE;
extern int OBlevel = 90;//зона перекуплености
extern int OSlevel=10;//зона перепроданости
extern bool EnterinOBOSzones = false;


extern string atr_ = "ATR settings";
extern int periodATR = 14;
extern double levelATR = 0.0002;
extern bool ATRup = true;//Вход возможен только если ATR идёт вверх(входная свеча и предыдущая)


extern string slugeb = "Service";
extern int slip=1;
extern int MaxAttempts=2;
extern int MAGIC=5443;


extern string trix = "TRIX settings";
extern int fast = 20;
extern int slow = 35;

extern int ePeriod1 = 1;
extern int ePeriod1Type = 1;
extern int ePeriod2 = 1;
extern int ePeriod2Type = 0;
extern int ePeriod3 = 5;
extern int ePeriod3Type = 1;
extern int ePeriod4 = 15;
extern int ePeriod4Type = 1;

int P1_position = 4;
int P2_position = 3;
int P3_position = 2;
int P4_position = 1;

bool autotimeframe = FALSE;
bool useSecondAutoTF = FALSE;

//+------------------------------------------------------------------+
double g_icustom_288;
double g_icustom_296;
double g_icustom_304;
double g_icustom_312;
int g_timeframe_332;
int g_timeframe_336;
int g_timeframe_340;
int g_timeframe_344;
int up1, do1, up2, do2, up3, do3, up4, do4;
int buy, sell;
double Point_;
static int prevtime = 0;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
  //min ATR level
  if (StringFind(Symbol(), "JPY", 0) != -1) levelATR*=100;

  //slippage
  if(MarketInfo(Symbol(), MODE_DIGITS) == 3 || MarketInfo(Symbol(), MODE_DIGITS) == 5)slip *=10;
  
   getPeriod();

   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   if (Digits <= 3) Point_ = 0.01;
   else Point_ = 0.0001;
   
   if (iTime(Symbol(), 0, 0) != prevtime)
{//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   prevtime = iTime(Symbol(),0,0);

   countOpenPosition(MAGIC);

   TRIX(1);
   
   if(Exitonchangedot1 && up1 == 1 && sell>0) CloseAll(OP_SELL, MAGIC);
   if(Exitonchangedot1 && do1 == 1 && buy>0) CloseAll(OP_BUY, MAGIC);
   if(Exitonchangedot2 && up2 == 1 && sell>0) CloseAll(OP_SELL, MAGIC);
   if(Exitonchangedot2 && do2 == 1 && buy>0) CloseAll(OP_BUY, MAGIC);
   
   int sig = SIGNAL();
   
   countOpenPosition(MAGIC);
   
   if(sig>0 && buy == 0) Buy(Lot, getATRStops(SL), getATRStops(TP), "", slip, MAGIC, MaxAttempts, Blue);
   if(sig<0 && sell == 0) Sell(Lot, getATRStops(SL), getATRStops(TP), "", slip, MAGIC, MaxAttempts, Red);

}//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
   countOpenPosition(MAGIC);
   
   if(Bezubitok && buy+sell>0) BU(MAGIC);

//----
   return(0);
  }
//+------------------------------------------------------------------+
int getATRStops(int ii) 
{
   int i;
   double ret = 0;
   if (ii > 0) {
      if (StringFind(Symbol(), "JPY", 0) != -1) i = 100;
      else i = 10000;
      ret = MathCeil(i * ii * iATR(NULL, 0, periodATR, 0));
   }
   return (ret);
}
//+------------------------------------------------------------------+
void CloseAll(int type, int MAGIC)
  {
int cmd = 0;
  for (int i=OrdersTotal()+1;i>=0; i--)
    {
    if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
      {//**
      RefreshRates();
      if(OrderType()==OP_BUY && OrderType()==type)
       {
        cmd = 0;
           for (int j = 0; cmd < 1 && j < MaxAttempts; j++)
            {
             waitIfBusy();
             cmd = OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid, Digits),slip, Blue);
             if(cmd<0) {Sleep(2000); RefreshRates();}
            }   
       }
      if(OrderType()==OP_SELL && OrderType()==type)
       {
        cmd = 0;
           for (j = 0; cmd < 1 && j < MaxAttempts; j++)
            {
             waitIfBusy();
             cmd = OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask, Digits),slip, Red);
             if(cmd<0) {Sleep(2000); RefreshRates();}
            }   
       }
      }//**
      }
    }
}
//+------------------------------------------------------------------+
int waitIfBusy() 
{   
   for (int Yx = 0; IsTradeContextBusy() && Yx < 50; Yx++) Sleep(125);   
   if (Yx >= 50) Print("Торговый поток занят больше ", DoubleToStr(25 * Yx / 1000, 2), " секунд");
   else if (Yx > 0) Print("Торговый поток был занят ", DoubleToStr(25 * Yx / 1000, 2), " секунд");   
   return (Yx);   
}
//+------------------------------------------------------------------+
void Buy(double Lot, int SL, int TP, string com, int slip, int MagicNumber, int MaxAttempts, color c = CLR_NONE)
{
 int ticket=0, cmd = 0;
 double tp = 0, sl = 0;
         for (int j = 0; ticket < 1 && j < MaxAttempts; j++)
         {
            waitIfBusy();
            ticket = OrderSend(Symbol(), OP_BUY, Lot, NormalizeDouble(Ask, Digits), slip, 0, 0, com, MagicNumber, 0, c);
            if(ticket<0) {Sleep(2000); RefreshRates();}
         }   
         if(ticket<0) 
         {
            Print("ОШИБКА: ",GetLastError()); 
         }
         if (ticket>0 && (TP>0 || SL>0))//
          {
           for (j = 0; cmd < 1 && j < MaxAttempts; j++)
            {
             waitIfBusy();
             OrderSelect(ticket, SELECT_BY_TICKET);
             if(TP>0) tp = OrderOpenPrice() + TP*Point_;
             if(SL>0) sl = OrderOpenPrice() - SL*Point_;
             cmd = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, Blue);
             if(cmd<0) {Sleep(2000); RefreshRates();}
            }   
          }
}
//+------------------------------------------------------------------+
void Sell(double Lot, int SL, int TP, string com, int slip, int MagicNumber, int MaxAttempts, color c = CLR_NONE)
{
 int ticket=0, cmd = 0;
 double tp = 0, sl = 0;
         for (int j = 0; ticket < 1 && j < MaxAttempts; j++)
         {
            waitIfBusy();
            ticket = OrderSend(Symbol(), OP_SELL, Lot, NormalizeDouble(Bid, Digits), slip, 0, 0, com, MagicNumber, 0, c);
            if(ticket<0) {Sleep(2000); RefreshRates();}
         }   
         if(ticket<0) 
         {
            Print("ОШИБКА: ",GetLastError()); 
         }
         if (ticket>0 && (TP>0 || SL>0))//
          {
           for (j = 0; cmd < 1 && j < MaxAttempts; j++)
            {
             waitIfBusy();
             OrderSelect(ticket, SELECT_BY_TICKET);
             if(TP>0) tp = OrderOpenPrice() - TP*Point_;
             if(SL>0) sl = OrderOpenPrice() + SL*Point_;
             cmd = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, Blue);
             if(cmd<0) {Sleep(2000); RefreshRates();}
            }   
          }
}
//+------------------------------------------------------------------+
void countOpenPosition(int MAGIC)
{
buy=0;sell=0;

for (int q=-1; q<OrdersTotal()+1; q++)
  {
  if (OrderSelect(q,SELECT_BY_POS,MODE_TRADES)==true)
    {
    if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MAGIC)continue;
      {          
      if(OrderType()==OP_BUY)      {buy++;}
      if(OrderType()==OP_SELL)     {sell++;}
      }
    }
  }
return;
} 
//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
int SIGNAL()
{
 if(StartHour<StopHour && (Hour()<StartHour || Hour()>=StopHour)) return(0);
 if(StartHour>StopHour && (Hour()<StartHour && Hour()>=StopHour)) return(0);
 
 int SIG1 = 0;
 int UP11, DO11, UP21, DO21, UP31, DO31, UP41, DO41;
 int UP12, DO12, UP22, DO22, UP32, DO32, UP42, DO42;
 TRIX(1);
 UP11 = up1; DO11 = do1; UP21 = up2; DO21 = do2; UP31 = up3; DO31 = do3; UP41 = up4; DO41 = do4;
 TRIX(2);
 UP12 = up1; DO12 = do1; UP22 = up2; DO22 = do2; UP32 = up3; DO32 = do3; UP42 = up4; DO42 = do4;
 
 int sumup = 0, sumdo = 0, sumup2 = 0, sumdo2 = 0;
 sumup = UP11 + UP21 + UP31 + UP41;
 sumdo = DO11 + DO21 + DO31 + DO41;
 sumup2 = UP12 + UP22 + UP32 + UP42;
 sumdo2 = DO12 + DO22 + DO32 + DO42;
 
 if(sumup == 4 && sumup2<4) SIG1 = 1;
 if(sumdo == 4 && sumdo2<4) SIG1 = -1;
 
 if((sumup == 4 || (sumup == 3 && Ignor1dotforenter)) && UP12 == 1 && UP22 == 0 && UP32 == 1 && UP42 == 1 && Enterdot2changed) SIG1 = 1;
 if((sumup == 4 || (sumup == 3 && Ignor1dotforenter)) && UP12 == 1 && UP22 == 1 && UP32 == 0 && UP42 == 1 && Enterdot3changed) SIG1 = 1;
 if((sumup == 4 || (sumup == 3 && Ignor1dotforenter)) && UP12 == 0 && UP22 == 1 && UP32 == 0 && UP42 == 1 && twodotschangestogather13) SIG1 = 1;
 if((sumup == 4 || (sumup == 3 && Ignor1dotforenter)) && UP12 == 1 && UP22 == 0 && UP32 == 1 && UP42 == 0 && twodotschangestogather24) SIG1 = 1;
 if((sumup == 4 || (sumup == 3 && Ignor1dotforenter)) && UP12 == 0 && UP22 == 0 && UP32 == 1 && UP42 == 1 && twodotschangestogather12) SIG1 = 1;
 if((sumup == 4 || (sumup == 3 && Ignor1dotforenter)) && UP12 == 1 && UP22 == 1 && UP32 == 0 && UP42 == 0 && twodotschangestogather34) SIG1 = 1;

 if((sumdo == 4 || (sumdo == 3 && Ignor1dotforenter)) && DO12 == 1 && DO22 == 0 && DO32 == 1 && DO42 == 1 && Enterdot2changed) SIG1 = -1;
 if((sumdo == 4 || (sumdo == 3 && Ignor1dotforenter)) && DO12 == 1 && DO22 == 1 && DO32 == 0 && DO42 == 1 && Enterdot3changed) SIG1 = -1;
 if((sumdo == 4 || (sumdo == 3 && Ignor1dotforenter)) && DO12 == 0 && DO22 == 1 && DO32 == 0 && DO42 == 1 && twodotschangestogather13) SIG1 = -1;
 if((sumdo == 4 || (sumdo == 3 && Ignor1dotforenter)) && DO12 == 1 && DO22 == 0 && DO32 == 1 && DO42 == 0 && twodotschangestogather24) SIG1 = -1;
 if((sumdo == 4 || (sumdo == 3 && Ignor1dotforenter)) && DO12 == 0 && DO22 == 0 && DO32 == 1 && DO42 == 1 && twodotschangestogather12) SIG1 = -1;
 if((sumdo == 4 || (sumdo == 3 && Ignor1dotforenter)) && DO12 == 1 && DO22 == 1 && DO32 == 0 && DO42 == 0 && twodotschangestogather34) SIG1 = -1;

 if(enterifsamewaydot34>0)
 {//+
  int i = 1;
  while(i<=enterifsamewaydot34)
   {
    TRIX(i);
    if(SIG1 == 1)
     {
      if(up3 < 1 || up4 < 1) {SIG1 = 0; return(0);}
     }
    if(SIG1 == -1)
     {
      if(do3 < 1 || do4 < 1) {SIG1 = 0; return(0);}
     }
    i++;
   }
 }//+
 if(enterifopositewaydot2>0)
 {//+
  i = 1;
  while(i<=enterifopositewaydot2)
   {
    TRIX(i);
    if(SIG1 == 1)
     {
      if(up2 == 1) {SIG1 = 0; return(0);}
     }
    if(SIG1 == -1)
     {
      if(do2 == 1) {SIG1 = 0; return(0);}
     }
    i++;
   }
 }//+
 if(candexitandnewenter>0)
 {
  if(GetLastExit()<candexitandnewenter) {SIG1 = 0; return(0);}
 }
 if(candenternewenterdot2 && GetLastEnter()>0)
 {//+
  bool ok = false;
  i = 1;
  while(i<GetLastEnter())
   {
    TRIX(i);
    if(SIG1 == 1)
     {
      if(do2 == 1) {ok = true; break;}
     }
    if(SIG1 == -1)
     {
      if(up2 == 1) {ok = true; break;}
     }
    i++;
   }
  if(!ok) {SIG1 = 0; return(0);}
 }//+
 
 if(telosize>0 && MathAbs(Open[1]-Close[1])<telosize*Point_) {SIG1 = 0; return(0);}
 if(maxsize>0 && MathAbs(High[1]-Low[1])>maxsize*Point_) {SIG1 = 0; return(0);}
 if(minsize>0 && MathAbs(High[1]-Low[1])<minsize*Point_) {SIG1 = 0; return(0);}
 
 if(shadow>0)
  {
   if(SIG1 == 1 && Open[1]>Close[1] && High[1]-Open[1]>shadow*Point_) {SIG1 = 0; return(0);}
   if(SIG1 == 1 && Open[1]<Close[1] && High[1]-Close[1]>shadow*Point_) {SIG1 = 0; return(0);}
   if(SIG1 == -1 && Open[1]>Close[1] && Close[1]-Low[1]>shadow*Point_) {SIG1 = 0; return(0);}
   if(SIG1 == -1 && Open[1]<Close[1] && Open[1]-Low[1]>shadow*Point_) {SIG1 = 0; return(0);}
  }

 double rsi = iRSI(NULL, 0, periodRSI, applied_priceRSI, 1);

// if(EnterinOBOSzones)
// {
//  if(SIG1 == 1 && rsi<OBlevel) {SIG1 = 0; return(0);}
//  if(SIG1 == -1 && rsi>OSlevel) {SIG1 = 0; return(0);}
// }
 if(!EnterinOBOSzones)
 {
  if(SIG1 == 1 && rsi>=OBlevel) {SIG1 = 0; return(0);}
  if(SIG1 == -1 && rsi<=OSlevel) {SIG1 = 0; return(0);}
 }
// return(SIG1);
 
 if(mincandlesRSI>0)
  {
   i = 1;
   while(i<=mincandlesRSI)
    {
     rsi = iRSI(NULL, 0, periodRSI, applied_priceRSI, i);
     if(rsi>=OBlevel || rsi<=OSlevel) {SIG1 = 0; return(0);}
   i++;
    }
  }

 double atr1 = iATR(NULL, 0, periodATR, 1);
 double atr2 = iATR(NULL, 0, periodATR, 1);
 
 if(ATRup && atr1<=atr2) {SIG1 = 0; return(0);}
 if(atr1<levelATR) {SIG1 = 0; return(0);}
 
 if(MathAbs(Close[0]-iMA(Symbol(),0,period_MA,0,MODE_LWMA,PRICE_CLOSE,1))<=nearMA*Point_) {SIG1 = 0; return(0);}
 
 if(nearHighLow)
 {
  if(MathAbs(iLow(NULL, PERIOD_D1, 0)-Close[0])>PipsnearHighLow*Point_ && MathAbs(iHigh(NULL, PERIOD_D1, 0)-Close[0])>PipsnearHighLow*Point_) {SIG1 = 0; return(0);}
 }
 if(!nearHighLow)
 {
  if(MathAbs(iLow(NULL, PERIOD_D1, 0)-Close[0])<=PipsnearHighLow*Point_ && MathAbs(iHigh(NULL, PERIOD_D1, 0)-Close[0])<=PipsnearHighLow*Point_) {SIG1 = 0; return(0);}
 }


 return(SIG1);
}
//+------------------------------------------------------------------+
int GetLastExit()
{
if(OrdersHistoryTotal() == 0) return(10000);
for (int q=OrdersHistoryTotal()+1; q>=0; q--)
  {
  if (OrderSelect(q,SELECT_BY_POS,MODE_HISTORY)==true)
    {
    if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MAGIC)continue;
      {
       return(iBarShift(NULL, 0, OrderCloseTime(), false));
      }
    }
  }
return(10000);
}
//+------------------------------------------------------------------+
int GetLastEnter()
{
if(OrdersHistoryTotal() == 0) return(0);
for (int q=OrdersHistoryTotal()+1; q>=0; q--)
  {
  if (OrderSelect(q,SELECT_BY_POS,MODE_HISTORY)==true)
    {
    if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MAGIC)continue;
      {
       return(iBarShift(NULL, 0, OrderOpenTime(), false));
      }
    }
  }
return(0);
}
//+------------------------------------------------------------------+
void TRIX(int i)
{
   int lia_28[];
   int lia_32[];
   int lia_36[];
   int lia_40[];
   int li_60;
   int l_timeframe_64;

   ArrayCopySeries(lia_40, 5, Symbol(), g_timeframe_332);
   ArrayCopySeries(lia_36, 5, Symbol(), g_timeframe_336);
   ArrayCopySeries(lia_32, 5, Symbol(), g_timeframe_340);
   ArrayCopySeries(lia_28, 5, Symbol(), g_timeframe_344);
   int l_index_44 = 0;
   int l_index_48 = 0;
   int l_index_52 = 0;
   int l_index_56 = 0;
   int l_index_8 = i;
   l_index_44 = 0;
   l_index_48 = 0;
   l_index_52 = 0;
   l_index_56 = 0;

      if (Time[l_index_8] < lia_40[l_index_44]) l_index_44++;
      if (Time[l_index_8] < lia_36[l_index_48]) l_index_48++;
      if (Time[l_index_8] < lia_32[l_index_52]) l_index_52++;
      if (Time[l_index_8] < lia_28[l_index_56]) l_index_56++;
      for (int li_12 = 1; li_12 <= 4; li_12++) {
         switch (li_12) {
         case 1:
            l_timeframe_64 = g_timeframe_332;
            li_60 = l_index_44;
            break;
         case 2:
            l_timeframe_64 = g_timeframe_336;
            li_60 = l_index_48;
            break;
         case 3:
            l_timeframe_64 = g_timeframe_340;
            li_60 = l_index_52;
            break;
         case 4:
            l_timeframe_64 = g_timeframe_344;
            li_60 = l_index_56;
         }
         g_icustom_288 = iCustom(NULL, l_timeframe_64, "THV4 Trix called", fast, slow, 6, li_60);
         g_icustom_296 = iCustom(NULL, l_timeframe_64, "THV4 Trix called", fast, slow, 6, li_60 + 1);
         g_icustom_304 = iCustom(NULL, l_timeframe_64, "THV4 Trix called", fast, slow, 7, li_60);
         g_icustom_312 = iCustom(NULL, l_timeframe_64, "THV4 Trix called", fast, slow, 7, li_60 + 1);
         if (autotimeframe == TRUE) {
            switch (li_12) {
            case 1:
               do1 = 0;
               up1 = 0;
               if (g_icustom_288 < g_icustom_296) do1 = 1.0;
               else up1 = 1.0;
               break;
            case 2:
               do2 = 0;
               up2 = 0;
               if (g_icustom_304 < g_icustom_312) do2 = 1.0;
               else up2 = 1.0;
               break;
            case 3:
               do3 = 0;
               up3 = 0;
               if (g_icustom_288 < g_icustom_296) do3 = 1.0;
               else up3 = 1.0;
               break;
            case 4:
               do4 = 0;
               up4 = 0;
               if (g_icustom_304 < g_icustom_312) do4 = 1.0;
               else up4 = 1.0;
            }
         } else {
            if (autotimeframe == FALSE) {
               switch (li_12) {
               case 1:
                  do1 = 0;
                  up1 = 0;
                  if (ePeriod1Type == 0) {
                     if (g_icustom_304 < g_icustom_312) do1 = 1.0;
                     else up1 = 1.0;
                  }
                  if (ePeriod1Type == 1) {
                     if (g_icustom_288 < g_icustom_296) do1 = 1.0;
                     else up1 = 1.0;
                  }
                  break;
               case 2:
                  do2 = 0;
                  up2 = 0;
                  if (ePeriod2Type == 0) {
                     if (g_icustom_304 < g_icustom_312) do2 = 1.0;
                     else up2 = 1.0;
                  }
                  if (ePeriod2Type == 1) {
                     if (g_icustom_288 < g_icustom_296) do2 = 1.0;
                     else up2 = 1.0;
                  }
                  break;
               case 3:
                  do3 = 0;
                  up3 = 0;
                  if (ePeriod3Type == 0) {
                     if (g_icustom_304 < g_icustom_312) do3 = 1.0;
                     else up3 = 1.0;
                  }
                  if (ePeriod3Type == 1) {
                     if (g_icustom_288 < g_icustom_296) do3 = 1.0;
                     else up3 = 1.0;
                  }
                  break;
               case 4:
                  do4 = 0;
                  up4 = 0;
                  if (ePeriod4Type == 0) {
                     if (g_icustom_304 < g_icustom_312) do4 = 1.0;
                     else up4 = 1.0;
                  }
                  if (ePeriod4Type == 1) {
                     if (g_icustom_288 < g_icustom_296) do4 = 1.0;
                     else up4 = 1.0;
                  }
               }
            }
         }
      }

   return (0);
}
//+-------------------------------------------------------------------------------------+
void getPeriod() {
   if (autotimeframe) {
      if (useSecondAutoTF == TRUE) {
         switch (Period()) {
         case PERIOD_M1:
            g_timeframe_332 = 30;
            g_timeframe_336 = 30;
            g_timeframe_340 = 60;
            g_timeframe_344 = 60;
            return;
         case PERIOD_M5:
            g_timeframe_332 = 60;
            g_timeframe_336 = 60;
            g_timeframe_340 = 240;
            g_timeframe_344 = 240;
            return;
         case PERIOD_M15:
            g_timeframe_332 = 240;
            g_timeframe_336 = 240;
            g_timeframe_340 = 1440;
            g_timeframe_344 = 1440;
            return;
         case PERIOD_M30:
            g_timeframe_332 = 1440;
            g_timeframe_336 = 1440;
            g_timeframe_340 = 10080;
            g_timeframe_344 = 10080;
            return;
         case PERIOD_H1:
            g_timeframe_332 = 10080;
            g_timeframe_336 = 10080;
            g_timeframe_340 = 43200;
            g_timeframe_344 = 43200;
            return;
         case PERIOD_H4:
            g_timeframe_332 = 1440;
            g_timeframe_336 = 1440;
            g_timeframe_340 = 10080;
            g_timeframe_344 = 10080;
            return;
         case PERIOD_D1:
            g_timeframe_332 = 10080;
            g_timeframe_336 = 10080;
            g_timeframe_340 = 43200;
            g_timeframe_344 = 43200;
            return;
         case PERIOD_W1:
            g_timeframe_332 = 43200;
            g_timeframe_336 = 43200;
            g_timeframe_340 = 43200;
            g_timeframe_344 = 43200;
            return;
         case PERIOD_MN1:
            g_timeframe_332 = 43200;
            g_timeframe_336 = 43200;
            g_timeframe_340 = 43200;
            g_timeframe_344 = 43200;
            return;
         }
      }
      switch (Period()) {
      case PERIOD_M1:
         g_timeframe_332 = 5;
         g_timeframe_336 = 5;
         g_timeframe_340 = 15;
         g_timeframe_344 = 15;
         return;
      case PERIOD_M5:
         g_timeframe_332 = 15;
         g_timeframe_336 = 15;
         g_timeframe_340 = 30;
         g_timeframe_344 = 30;
         return;
      case PERIOD_M15:
         g_timeframe_332 = 30;
         g_timeframe_336 = 30;
         g_timeframe_340 = 60;
         g_timeframe_344 = 60;
         return;
      case PERIOD_M30:
         g_timeframe_332 = 60;
         g_timeframe_336 = 60;
         g_timeframe_340 = 240;
         g_timeframe_344 = 240;
         return;
      case PERIOD_H1:
         g_timeframe_332 = 240;
         g_timeframe_336 = 240;
         g_timeframe_340 = 1440;
         g_timeframe_344 = 1440;
         return;
      case PERIOD_H4:
         g_timeframe_332 = 1440;
         g_timeframe_336 = 1440;
         g_timeframe_340 = 10080;
         g_timeframe_344 = 10080;
         return;
      case PERIOD_D1:
         g_timeframe_332 = 10080;
         g_timeframe_336 = 10080;
         g_timeframe_340 = 43200;
         g_timeframe_344 = 43200;
         return;
      case PERIOD_W1:
         g_timeframe_332 = 43200;
         g_timeframe_336 = 43200;
         g_timeframe_340 = 43200;
         g_timeframe_344 = 43200;
         return;
      case PERIOD_MN1:
         g_timeframe_332 = 43200;
         g_timeframe_336 = 43200;
         g_timeframe_340 = 43200;
         g_timeframe_344 = 43200;
         return;
      }
   }
   string ls_8 = "Invalid timeframe. Please enter a valid timeframe";
   if (validateInput(ePeriod1) == 0) Alert(ls_8);
   else g_timeframe_332 = ePeriod1;
   if (validateInput(ePeriod2) == 0) Alert(ls_8);
   else g_timeframe_336 = ePeriod2;
   if (validateInput(ePeriod3) == 0) Alert(ls_8);
   else g_timeframe_340 = ePeriod3;
   if (validateInput(ePeriod4) == 0) {
      Alert(ls_8);
      return;
   }
   g_timeframe_344 = ePeriod4;
}
//+-------------------------------------------------------------------------------------+
int validateInput(int ai_0) {
   bool li_ret_4 = FALSE;
   switch (ai_0) {
   case 1:
      li_ret_4 = TRUE;
      break;
   case 5:
      li_ret_4 = TRUE;
      break;
   case 15:
      li_ret_4 = TRUE;
      break;
   case 30:
      li_ret_4 = TRUE;
      break;
   case 1:
      li_ret_4 = TRUE;
      break;
   case 60:
      li_ret_4 = TRUE;
      break;
   case 240:
      li_ret_4 = TRUE;
      break;
   case 1440:
      li_ret_4 = TRUE;
      break;
   case 10080:
      li_ret_4 = TRUE;
      break;
   case 43200:
      li_ret_4 = TRUE;
   }
   return (li_ret_4);
}
//+-------------------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
void BU(int MAGIC)
{
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==Symbol() && OrderMagicNumber() == MAGIC)
      {
       BU_();
      }
    }
  }
}

//+----------------------------------------------------------------------------+
void BU_()
{
  double pa, pb, pp;
  pp=Point_;
  
  if (OrderType()==OP_BUY) {
    RefreshRates();
    pb=MarketInfo(OrderSymbol(), MODE_BID);

      if (pb>OrderOpenPrice()+(BULevel-1)*pp && (OrderStopLoss()<OrderOpenPrice())) {
        ModifyOrder(-1, OrderOpenPrice()+BUsize*pp, -1);
        return;
      }
    }

  if (OrderType()==OP_SELL) {
    RefreshRates();
    pa=MarketInfo(OrderSymbol(), MODE_ASK);

      if (pa<OrderOpenPrice()-(BULevel-1)*pp && (OrderStopLoss()>OrderOpenPrice() || OrderStopLoss()==0)) {
        ModifyOrder(-1, OrderOpenPrice()-BUsize*pp, -1);
        return;
      }
    }

}

//+----------------------------------------------------------------------------+
void ModifyOrder(double pp=-1, double sl=0, double tp=0, datetime ex=0) {
  bool   fm;
  color  cl=Yellow;
  double op, pa, pb, os, ot;
  int    dg=MarketInfo(OrderSymbol(), MODE_DIGITS), er, it;

  if (pp<=0) pp=OrderOpenPrice();
  if (sl<0 ) sl=OrderStopLoss();
  if (tp<0 ) tp=OrderTakeProfit();
  
  pp=NormalizeDouble(pp, dg);
  sl=NormalizeDouble(sl, dg);
  tp=NormalizeDouble(tp, dg);
  op=NormalizeDouble(OrderOpenPrice() , dg);
  os=NormalizeDouble(OrderStopLoss()  , dg);
  ot=NormalizeDouble(OrderTakeProfit(), dg);

  if (pp!=op || sl!=os || tp!=ot) {
    for (it=1; it<=MaxAttempts; it++) {
      if (!IsTesting() && (!IsExpertEnabled() || IsStopped())) break;
      while (!IsTradeAllowed()) Sleep(5000);
      RefreshRates();
      fm=OrderModify(OrderTicket(), pp, sl, tp, ex, cl);
      if (fm) {
         break;
      } else {
        er=GetLastError();
        pa=MarketInfo(OrderSymbol(), MODE_ASK);
        pb=MarketInfo(OrderSymbol(), MODE_BID);
        Print("Error(",er,") modifying order... try ",it);
        Print("Ask=",pa,"  Bid=",pb,"  sy=",OrderSymbol(),"  pp=",pp,"  sl=",sl,"  tp=",tp);
        Sleep(1000*10);
      }
    }
  }
}

//+----------------------------------------------------------------------------+

