//+------------------------------------------------------------------+
//|                                                     @VaBank2.mq4 |
//|                                                   Леонид Киндеев |
//|                                               leo.kindeev@tut.by |
//+------------------------------------------------------------------+

#property indicator_chart_window

//--------------------------------------------------------------------------
enum TIMEFRAME
{                       
D1,  //День                      
W1   //Неделя                       
};
input TIMEFRAME  TimeFrame = W1;  
  
extern string CurPairWeek     = "EURUSD,EURJPY,EURCAD,GBPUSD,GBPJPY,GBPCAD";
extern string CurPairDay      = "EURUSD,EURJPY,EURCAD,GBPUSD,GBPJPY,GBPCAD";             
extern double Depo            = 2000;
extern double StopLossWeek    = 100;
extern double StopLossDay     = 50;
extern double RiskPercentWeek = 50;
extern double RiskPercentDay  = 10;
extern int    AveragePeriod   = 10;          // Период для расчета усредненных значений
extern int    Ystart          = 10;          // Смещение текста по вертикали
extern int    Xstart          = 5;           // Смещение текста по горизонтали
extern int    Ystep           = 12;          // Шаг смещения текста по вертикали
extern int    Xstep           = 5;           // Шаг смещения текста по горизонтали
extern string Font            = "Calibri";   // Шрифт текста
extern int    FontSize        = 8;           // Размер шрифта
extern color  CurrentValueColor = Blue;         // Цвет списка пар со значениями текущего периода
extern color  PrevValueColor    = Teal;         // Цвет списка пар со значениями предыдущего периода
extern color  MaxPrevValueColor = Magenta;      // Цвет списка пар с макс.значениями предыдущего периода
extern color  InfoValueColor    = Purple;       // Цвет дополн. информации

double pairsize[], pairsizepre[], pairavg[], pairavgpre[];
string pairnames[], pairnamespre[];

int timeprev;
int period;

int np;
int maxnp=30;
string pair[];
double size[];
double avg [];

int mainIndex;
double StopLoss, RiskPercent;

int Xdepo,Xperiod,Xname,Xvalue,Xinfo,Xperiodpre,Xnamepre,Xvaluepre;

int Ydepo,Yperiod,Ypairs;

string buttonPeriodID="buttonPeriod";
int XbuttonPeriod,YbuttonPeriod;

string buttonPrePeriodID="buttonPrePeriod";
int XbuttonPrePeriod,YbuttonPrePeriod;

string buttonCurPeriodID="buttonCurPeriod";
int XbuttonCurPeriod,YbuttonCurPeriod;

string buttonNextPeriodID="buttonNextPeriod";
int XbuttonNextPeriod,YbuttonNextPeriod;

//--------------------------------------------------------------------------
int OnInit()
   {
   DeleteObjects();
   
   Xdepo=Xstart+18*Xstep;
   Xperiod=Xstart;
   Xname=Xstart;
   Xvalue=Xname+9*Xstep;
   Xinfo=Xvalue+25*Xstep;
   Xperiodpre=Xinfo+23*Xstep;
   Xnamepre=Xperiodpre;
   Xvaluepre=Xnamepre+9*Xstep;
   
   Ydepo=Ystart+0*Ystep;
   Yperiod=Ydepo+3*Ystep;
   Ypairs=Yperiod+2*Ystep;

   XbuttonPeriod=Xstart;
   YbuttonPeriod=Ystart;

   XbuttonPrePeriod=Xperiodpre;
   YbuttonPrePeriod=Ydepo+2*Ystep-7;

   XbuttonCurPeriod=XbuttonPrePeriod+27;
   YbuttonCurPeriod=YbuttonPrePeriod;

   XbuttonNextPeriod=XbuttonCurPeriod+20;
   YbuttonNextPeriod=YbuttonCurPeriod;

   ArrayResize(pair,maxnp);
   ArrayResize(pairsize,maxnp);
   ArrayResize(pairsizepre,maxnp);
   ArrayResize(size,maxnp);
   ArrayResize(pairnames,maxnp);
   ArrayResize(pairnamespre,maxnp);
   ArrayResize(avg,maxnp);
   ArrayResize(pairavg,maxnp);
   ArrayResize(pairavgpre,maxnp);
   
   mainIndex=0;
   
   if (TimeFrame==W1)
      period=PERIOD_W1;
   else
      period=PERIOD_D1;
      
   Init ();
   
   return(INIT_SUCCEEDED);
   }
//--------------------------------------------------------------------------
void Init()
   {
   string buttonPeriodText;
   DeleteObjects();
   
   int kodrazd=StringGetCharacter(",",0);
   if (period==PERIOD_W1)
      {
      np = StringSplit(CurPairWeek,kodrazd,pair);
      buttonPeriodText="ДЕНЬ";
      StopLoss=StopLossWeek;
      RiskPercent=RiskPercentWeek;
      }
   else
      {
      np = StringSplit(CurPairDay,kodrazd,pair);
      buttonPeriodText="НЕДЕЛЯ";
      StopLoss=StopLossDay;
      RiskPercent=RiskPercentDay;
      }
   
   if (np>maxnp) np=maxnp;
      
   timeprev=iTime(Symbol(),period,mainIndex+1);
   
   SetPairsForPrevPeriod();
   
   // Кнопка смены периодов (Неделя/День)
   ObjectDelete(0,buttonPeriodID);
   CreateButton(buttonPeriodID, XbuttonPeriod, YbuttonPeriod, 75, 25, buttonPeriodText, "Переключение периодов");
   
   // Кнопка перехода к пред. периоду (<<)
   ObjectDelete(0,buttonPrePeriodID);
   CreateButton(buttonPrePeriodID, XbuttonPrePeriod, YbuttonPrePeriod, 25, 17, "<<", "На один период назад");
   
   // Кнопка возврата к тек. периоду (O)
   ObjectDelete(0,buttonCurPeriodID);
   CreateButton(buttonCurPeriodID, XbuttonCurPeriod, YbuttonCurPeriod, 18, 17, "O", "К текущему периоду");
   
   // Кнопка перехода к след. периоду (>>)
   ObjectDelete(0,buttonNextPeriodID);
   CreateButton(buttonNextPeriodID, XbuttonNextPeriod, YbuttonNextPeriod, 25, 17, ">>", "На один период вперед");

   }
//--------------------------------------------------------------------------
void OnDeinit(const int reason)
   {
   DeleteObjects();
   }
//--------------------------------------------------------------------------
void DeleteObjects() 
   {
   ObjectDelete("depostoprisk");
   ObjectDelete("period");
   ObjectDelete("periodpre");
   ObjectDelete("periodname");
   ObjectDelete(0,buttonPeriodID);
   ObjectDelete(0,buttonPrePeriodID);
   ObjectDelete(0,buttonCurPeriodID);
   ObjectDelete(0,buttonNextPeriodID);
   
   for (int i=0; i<np; i++) 
      {
      ObjectDelete("name"+pair[i]);
      ObjectDelete("value"+pair[i]);
      ObjectDelete("info"+pair[i]);
      ObjectDelete("name"+pair[i]+"pre");
      ObjectDelete("value"+pair[i]+"pre");
      }
   }
//--------------------------------------------------------------------------
void CreateButton(string buttonID, int Xbutton, int Ybutton, int Xsize, int Ysize, string textButton, string textToolTip)
   {
   ObjectCreate(0,buttonID,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,buttonID,OBJPROP_COLOR,Black);
   ObjectSetInteger(0,buttonID,OBJPROP_BGCOLOR,Silver);
   ObjectSetInteger(0,buttonID,OBJPROP_XDISTANCE,Xbutton);
   ObjectSetInteger(0,buttonID,OBJPROP_YDISTANCE,Ybutton);
   ObjectSetInteger(0,buttonID,OBJPROP_XSIZE,Xsize);
   ObjectSetInteger(0,buttonID,OBJPROP_YSIZE,Ysize);
   ObjectSetString(0,buttonID,OBJPROP_FONT,"Calibri");
   ObjectSetString(0,buttonID,OBJPROP_TEXT,textButton);
   ObjectSetInteger(0,buttonID,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,buttonID,OBJPROP_SELECTABLE,true);
   ObjectSetString(0,buttonID,OBJPROP_TOOLTIP,textToolTip);
   }
//--------------------------------------------------------------------------
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
   {
   
   if(id==CHARTEVENT_OBJECT_CLICK) // если нажата кнопка мышки
      {
      string clickedChartObject=sparam;
      if(clickedChartObject==buttonPeriodID) // щелчок по кнопке Период (Неделя/день)
         { 
         mainIndex=0; // возвращаемся к тек. периоду
         // меняем периоды
         if (period==PERIOD_D1)
            period=PERIOD_W1;
         else
            period=PERIOD_D1;
         }
         
      if(clickedChartObject==buttonPrePeriodID) // щелчок по кнопке Пред.Период (<<)
         { // увеличиваем главный индекс
         mainIndex++;
         }
         
      if(clickedChartObject==buttonCurPeriodID) // щелчок по кнопке Тек.Период (О)
         { // увеличиваем главный индекс
         mainIndex=0;
         }
         
       if(clickedChartObject==buttonNextPeriodID) // щелчок по кнопке След.Период (>>)
         { // уменьшаем главный индекс
         if (mainIndex > 0) mainIndex--;
         }
            
      Init();   
      SetDepoStopRisk();
      SetPeriodNames();
      SetPairsForCurrentPeriod();
      SetInfo();

      ChartRedraw();// принудительно перерисуем все объекты на графике
      }
   }
//--------------------------------------------------------------------------
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
   {
   SetDepoStopRisk();
   SetPeriodNames();
   
   if (timeprev != iTime(Symbol(),period,mainIndex+0))
      {
      SetPairsForPrevPeriod();
      timeprev = iTime(Symbol(),period,mainIndex+0);
      }
      
   SetPairsForCurrentPeriod();
   SetInfo();
   
   return(rates_total);
   }
//--------------------------------------------------------------------------
void SetDepoStopRisk()
   {
   string DepoStopRisk="Depo="+DoubleToStr(Depo,0)+"   StopLoss="+DoubleToStr(StopLoss,0)+
                       "   Risk="+DoubleToStr(RiskPercent,0)+"%   AveragePeriod=" + IntegerToString(AveragePeriod);
   SetLabel("depostoprisk", DepoStopRisk, InfoValueColor, Xdepo, Ydepo);
   }
   //--------------------------------------------------------------------------
void SetPeriodNames()
   {
   string dayofweek[7]={"вск","пнд","втр","срд","чтв","птн","сбт"};
   
   string data=TimeToString(iTime(Symbol(),period,mainIndex+0),TIME_DATE);
   string datapre=TimeToString(iTime(Symbol(),period,mainIndex+1),TIME_DATE);
   string dw=dayofweek[TimeDayOfWeek(iTime(Symbol(),period,mainIndex+0))];
   string dwpre=dayofweek[TimeDayOfWeek(iTime(Symbol(),period,mainIndex+1))];
   
   if (period==PERIOD_W1)
      {
      SetLabel("period", "текущая ("+data+" "+dw+")", InfoValueColor, Xperiod, Yperiod);
      SetLabel("periodpre", "предыдущая ("+datapre+" "+dwpre+")", InfoValueColor, Xperiodpre, Yperiod);
      SetLabel("periodname", "НЕДЕЛЯ", InfoValueColor, Xinfo, Yperiod);
      }
   else
      {
      SetLabel("period", "текущий ("+data+" "+dw+")", InfoValueColor, Xperiod, Yperiod);
      SetLabel("periodpre", "предыдущий ("+datapre+" "+dwpre+")", InfoValueColor, Xperiodpre, Yperiod);
      SetLabel("periodname", "ДЕНЬ", InfoValueColor, Xinfo, Yperiod);
      }
   }
//--------------------------------------------------------------------------
void SetPairsForPrevPeriod()
   { 
   // Рассчитывает размеры тел пар прошлого периода и сортирует пары в порядке убывания.
   // Результат в массивах pair и size
   CalculateAndSortPairSizes(1);
   
   ArrayCopy(pairnamespre, pair);
   ArrayCopy(pairsizepre, size);
   ArrayCopy(pairavgpre, avg);
   
   int y=Ypairs;
   for (int i=0; i<np; i++)
      {
      string pairValue = CalculatePairValue(pairnamespre[i], pairsizepre[i], pairavgpre[i], 1);

      color clr;
      if (i<3) clr=MaxPrevValueColor; else clr=PrevValueColor;
      SetLabel("name"+pairnamespre[i]+"pre", pairnamespre[i], clr, Xnamepre, y);
      SetLabel("value"+pairnamespre[i]+"pre", pairValue, clr, Xvaluepre, y);
      y=y+Ystep;
      }
   }
//--------------------------------------------------------------------------
void SetPairsForCurrentPeriod()
   {
   // Рассчитывает размеры тел пар текущего периода и сортирует пары в порядке убывания.
   // Результат в массивах pair и size
   CalculateAndSortPairSizes(0);
   
   ArrayCopy(pairnames, pair);
   ArrayCopy(pairsize, size);
   ArrayCopy(pairavg, avg);
   
   int y=Ypairs;
   for (int i=0; i<np; i++)
      {
      string pairValue=CalculatePairValue(pairnames[i], pairsize[i], pairavg[i], 0);
      
      color clr=CurrentValueColor;
      if (pairnames[i]==pairnamespre[0] || pairnames[i]==pairnamespre[1] ||pairnames[i]==pairnamespre[2]) clr=MaxPrevValueColor;
      SetLabel("name"+pairnames[i], pairnames[i], clr, Xname, y);
      SetLabel("value"+pairnames[i], pairValue, clr, Xvalue, y);
      y=y+Ystep;
      }
   }
//--------------------------------------------------------------------------
void CalculateAndSortPairSizes(int index)
   {
   int i, j;
   
   // Заполнение массива размеров текущими значениями
   for (i=0; i<np; i++)
      {
      int k=0; 
      double point=0; 
      while (point==0 && k<3)
         {
         point=MarketInfo(pair[i],MODE_POINT);
         k++;
         }
         
      if (point>0) size[i]=MathAbs(iOpen(pair[i],period,mainIndex+index)-iClose(pair[i],period,mainIndex+index))/point;
      if (MarketInfo(pair[i],MODE_DIGITS)==3 || 
          MarketInfo(pair[i],MODE_DIGITS)==5) size[i]=NormalizeDouble(size[i]/10.,0);
          
      double N = 0;
      for (j=mainIndex+index+1; j<=mainIndex+index+AveragePeriod; j++)
         {
         N=N+MathAbs(iOpen(pair[i],period,j)-iClose(pair[i],period,j))/point;
         }
      N=NormalizeDouble(N/AveragePeriod,0);
      if (MarketInfo(pair[i],MODE_DIGITS)==3 || MarketInfo(pair[i],MODE_DIGITS)==5) N=NormalizeDouble(N/10.,0);
      avg[i]=N;
      }

   // Сортировка
   double max;
   for (i=0; i<np; i++)
      {
      max=size[i];
      for (j=i+1; j<np; j++)
         if (size[j]>max)
            {
            max=size[j];
            
            double s=size[i];
            size[i]=size[j];
            size[j]=s;
            
            string p=pair[i];
            pair[i]=pair[j];
            pair[j]=p;
            
            s=avg[i];
            avg[i]=avg[j];
            avg[j]=s;
            }
      }
   }
//--------------------------------------------------------------------------
string CalculatePairValue(string pairName, double pairSize, double pairAvg, int index)
   {
   string pairValue;
   double point=0;
   int k=0;
   while (point==0)
      {
      point=MarketInfo(pairName,MODE_POINT);
      k++;
      if (k>3) break;
      }
   
   string dir;
   string sign="";
   double sizeup, sizedn;
   if (point>0)
      {
      sizeup=(iHigh(pairName,period,mainIndex+index)-iOpen(pairName,period,mainIndex+index))/point;
      if (MarketInfo(pairName,MODE_DIGITS)==3 || MarketInfo(pairName,MODE_DIGITS)==5)
         sizeup=NormalizeDouble(sizeup/10.,0);
      sizedn=(iOpen(pairName,period,mainIndex+index)-iLow(pairName,period,mainIndex+index))/point;
      if (MarketInfo(pairName,MODE_DIGITS)==3 || MarketInfo(pairName,MODE_DIGITS)==5)
         sizedn=NormalizeDouble(sizedn/10.,0);
      if (iOpen(pairName,period,mainIndex+index+1)<=iClose(pairName,period,mainIndex+index+1)) //пред.свеча вверх
         {
         sizeup=-sizeup;
         if (iClose(pairName,period,mainIndex+index)>=iOpen(pairName,period,mainIndex+index)) // тек.свеча тоже вврех
            {
            sign="-";
            dir="up";
            }
         else
            {
            sign="+";
            dir="dn";
            }
         }
      else // пред. свеча вниз
         {
         sizedn=-sizedn;
         if (iClose(pairName,period,mainIndex+index)<iOpen(pairName,period,mainIndex+index)) // тек. свеча тоже вниз
            {
            sign="-";
            dir="dn";
            }
         else
            {
            sign="+";
            dir="up";
            }
         }
      }
   
   pairValue=sign+DoubleToStr(pairSize,0)+" "+dir+" ("+DoubleToStr(sizeup,0)+"/"+
             DoubleToStr(sizedn,0)+") avg"+DoubleToStr(pairAvg,0);
   return (pairValue);
   }
//--------------------------------------------------------------------------
void SetInfo()
   {
   int y=Ypairs;
   for (int i=0; i<np; i++)
      {
      double pipValue = MarketInfo(pairnames[i],MODE_TICKVALUE);
      if (pipValue>0)
         {
         double lots = NormalizeDouble(Depo*RiskPercent/100.0/StopLoss/pipValue,2);
         double spread = MarketInfo(pairnames[i],MODE_SPREAD);
         if (MarketInfo(pairnames[i],MODE_DIGITS)==3 || MarketInfo(pairnames[i],MODE_DIGITS)==5)
            {
            spread=NormalizeDouble(spread/10.,0);
            }
         SetLabel("info"+pairnames[i], "Lot="+DoubleToStr(lots,2)+
                  "  Spread="+spread, InfoValueColor, Xinfo, y);
         y=y+Ystep;
         }
      }
   }
//--------------------------------------------------------------------------
void SetLabel(string objname, string text, color colr, int x, int y) 
   {
   if (ObjectFind(objname) < 0) ObjectCreate(objname, OBJ_LABEL, 0, 0,0);
  
   ObjectSetText(objname, text, FontSize);
   ObjectSet(objname, OBJPROP_COLOR, colr);
   ObjectSet(objname, OBJPROP_XDISTANCE, x);
   ObjectSet(objname, OBJPROP_YDISTANCE, y);
   ObjectSet(objname, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE, FontSize);
   ObjectSetString( 0,objname,OBJPROP_FONT, Font);
   ObjectSetInteger(0,objname,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,objname,OBJPROP_TOOLTIP,"\n");
   }
//--------------------------------------------------------------------------
