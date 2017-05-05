//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#property link "http://forexbig.ru"
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_color1 Aqua 
#property indicator_color2 Aqua
#property indicator_color3 Aqua
#property indicator_color4 White
#property indicator_color5 White
#property indicator_color6 Red
#property indicator_color7 Blue
#property indicator_color8 Orchid

//Input Params
extern string PivotRangeStart = "00:30";
extern string PivotRangeEnd = "00:30";
extern bool DisplayPivotPoint = true;
extern bool DisplayPreviousHighLow = true;
extern bool DisplayMAs = false;

double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];
double Buffer5[];
double Buffer6[];
double Buffer7[];
double Buffer8[];

double pivots[50];

double pivotRangeHigh;
double pivotRangeLow;
double pivotRangeClose;
double pivotPoint;
double pivotDiff;

double pivotTop=0;
double pivotBottom=0;

double pivot14MA;
double pivot30MA;
double pivot50MA;

int openBar;
    
int init()
{
   SetIndexStyle(0,DRAW_LINE, STYLE_DOT, 1);
   SetIndexBuffer(0,Buffer1);
   SetIndexLabel(0,"Pivot Point");

   SetIndexStyle(1,DRAW_LINE, STYLE_DASH, 1);
   SetIndexBuffer(1,Buffer2);
   SetIndexLabel(1,"Pivot Range Top");

   SetIndexStyle(2,DRAW_LINE, STYLE_DASH, 1);
   SetIndexBuffer(2,Buffer3);
   SetIndexLabel(2,"Pivot Range Bottom");
   
   SetIndexStyle(3,DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(3,Buffer4);
   SetIndexLabel(3,"Previous Day High");
   
   SetIndexStyle(4,DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(4,Buffer5);
   SetIndexLabel(4,"Previous Day Low");
   
   SetIndexStyle(5,DRAW_LINE);
   SetIndexBuffer(5,Buffer6);
   SetIndexLabel(5,"14 MA");
   
   SetIndexStyle(6,DRAW_LINE);
   SetIndexBuffer(6,Buffer7);
   SetIndexLabel(6,"30 MA");
   
   SetIndexStyle(7,DRAW_LINE);
   SetIndexBuffer(7,Buffer8);
   SetIndexLabel(7,"50 MA");

   return(0);
}

int deinit()
{
   return(0);
}

int start()
{   
   string barTime="", lastBarTime="";         
   string barDay="", lastBarDay="";
   int closeBar;
          
   for(int i=Bars; i>=0; i--)
   {  
      barTime = TimeToStr(Time[i], TIME_MINUTES);
      lastBarTime = TimeToStr(Time[i+1], TIME_MINUTES);
      barDay = TimeToStr(Time[i],TIME_DATE);
      lastBarDay = TimeToStr(Time[i+1],TIME_DATE); 
      
      //need to handle if pivotrangestart/end is 00:00
      if ((PivotRangeEnd == "00:00" && barTime>=PivotRangeEnd && barDay>lastBarDay) || (barTime>=PivotRangeEnd && lastBarTime<PivotRangeEnd))
      {
         closeBar = i + 1;
         
         if (openBar>0)
         {
            calculatePivotRangeValues(openBar, closeBar);
         }
      }
      
      if ((PivotRangeStart == "00:00" && barTime>=PivotRangeStart && barDay>lastBarDay) || (barTime>=PivotRangeStart && lastBarTime<PivotRangeStart))
      {          
          openBar = i;
      }
      
      if (openBar>0)
      {
          drawIndicators(i);
      }     
   }
   return(0);
}

void calculatePivotRangeValues(int openBar, int closeBar)
{
   pivotRangeHigh = High[Highest(NULL, 0, MODE_HIGH, (openBar - closeBar + 1), closeBar)];
   pivotRangeLow = Low[Lowest(NULL, 0, MODE_LOW, (openBar - closeBar + 1), closeBar)];
   pivotRangeClose = Close[closeBar];
   pivotPoint = (pivotRangeHigh + pivotRangeLow + pivotRangeClose)/3;
   pivotDiff = MathAbs(((pivotRangeHigh + pivotRangeLow)/2) - pivotPoint);
   pivotTop = pivotPoint + pivotDiff;
   pivotBottom = pivotPoint - pivotDiff;
   
   if (DisplayMAs) calcPivotMA();
}

void calcPivotMA()
{
   //create temp array
   double pivs[50];
   
   //load new pivot
   ArrayCopy(pivs,pivots,1,0,49);
   pivs[0] = pivotPoint;
   ArrayCopy(pivots, pivs, 0, 0, WHOLE_ARRAY);
   
   //calcMA
   double pivSum = 0;
   int count = ArraySize(pivots);
   if (count>=14)
   {
      for (int p=0; p<count; p++)
      {
         pivSum+=pivots[p];
      
         if (p==13) 
         {
            pivot14MA = pivSum/14;
         }
         
         if (p==29) 
         {pivot30MA = pivSum/30;}
      
         if (p==49) 
         {pivot50MA = pivSum/50;}
      }
   }
}

void drawIndicators(int curBar)
{
   if (DisplayPivotPoint) Buffer1[curBar]=pivotPoint;
   
   Buffer2[curBar]=pivotTop;
   Buffer3[curBar]=pivotBottom;
   
   if (DisplayPreviousHighLow)
   {
      Buffer4[curBar]=pivotRangeHigh;
      Buffer5[curBar]=pivotRangeLow;
   }
   
   if (DisplayMAs)
   {
      Buffer6[curBar]=pivot14MA;
      Buffer7[curBar]=pivot30MA;
      Buffer8[curBar]=pivot50MA;
   }


}