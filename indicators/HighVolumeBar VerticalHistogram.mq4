
#property copyright "Scriptong"
#property link "scriptong@mail.ru"

#property indicator_chart_window                   

#define MAX_DAY_VOLATILITY             2000

// Настроечные параметры индикатора
extern color     i_supportColor        = C'79, 123, 153';
extern color     i_resistanceColor     = C'134, 53, 53';
extern color     i_indefiniteColor     = DarkGray;

extern int       i_indBarsCount        = 5000;


// Прочие глобальные переменные индикатора
bool g_activate,                                   // Признак успешной инициализации..
                                                   // ..индикатора
     g_init;                                       // Переменная для инициализации..
                                                   // ..статических переменных внутри..
                                                   // ..функций в момент проведения..
                                                   // ..повторной инициализации
int g_volumesArray[MAX_DAY_VOLATILITY];            // Массив для записи величин объемов

datetime g_lastCheckedBar;                         // Время открытия последнего..
                                                   // ..проверенного бара ТФ М1
     
#define PREFIX "HVBVH_"                            // Префикс графических объектов,..
                                                   // ..отображаемых индикатором 

#define SIGN_TREND_LINE               "TR_LINE_"   // Признак объекта "трендовая линия"


#include <stderror.mqh>
                                                   
//+-------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                            |
//+-------------------------------------------------------------------------------------+
int init()
{
   g_activate = false;                             // Индикатор не инициализирован
   g_init = true;
   g_lastCheckedBar = 0;
   
   if (!TuningParameters())                        // Неверно указанные значения..
      return (-1);                                 // ..настроечных параметров - причина
                                                   // ..неудачной инициализации
           
   IsAllBarsAvailable(PERIOD_M1);                  // Запуск подкачки данных по ТФ М1

   g_activate = true;                              // Индикатор успешно инициализирован
   return(0);
}
//+-------------------------------------------------------------------------------------+
//| Проверка корректности настроечных параметров                                        |
//+-------------------------------------------------------------------------------------+
bool TuningParameters()
{
   string name = WindowExpertName();

   if (Period() > PERIOD_H4)
   {
      Print(name, ": Индикатор не работает на таймфреймах выше, чем H4.");
      return (false);
   }

   int period = Period();
   if (period == 0)
   {
      Alert(name, ": фатальная ошибка терминала - период 0 минут. Индикатор отключен.");
      return (false);
   }
   
   if (Point == 0)
   {
      Alert(name, ": фатальная ошибка терминала - величина пункта равна нулю. ",
                  "Индикатор отключен.");
      return (false);
   }
   
   return (true);
}
//+-------------------------------------------------------------------------------------+
//| Проверка доступности баров указанного таймфрейма                                    |
//+-------------------------------------------------------------------------------------+
bool IsAllBarsAvailable(int tf)
{
   // Вычисление индекса бара, с которого необходимо начинать проверку
   if (g_lastCheckedBar == 0)
      int lastBar = iBars(NULL, tf) - 1;
   else
      lastBar = iBarShift(NULL, tf, g_lastCheckedBar);

   if (GetLastError() == ERR_HISTORY_WILL_UPDATED)
      return (false);
      
   // Проверка доступности баров
   for (int i = lastBar - 1; i > 0; i--)
   {
      iTime(NULL, tf, i);
      if (GetLastError() == ERR_HISTORY_WILL_UPDATED)
         return (false);
   }
   
   // Все бары доступны
   g_lastCheckedBar = iTime(NULL, tf, 1);
   return (true);
}
//+-------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                          |
//+-------------------------------------------------------------------------------------+
int deinit()
{
   DeleteAllObjects();
   return(0);
}
//+-------------------------------------------------------------------------------------+
//| Удаление всех объектов, созданных программой                                        |
//+-------------------------------------------------------------------------------------+
void DeleteAllObjects()
{
   for (int i = ObjectsTotal() - 1; i >= 0; i--)     
      if (StringSubstr(ObjectName(i), 0, StringLen(PREFIX)) == PREFIX)
         ObjectDelete(ObjectName(i));
}
//+-------------------------------------------------------------------------------------+
//| Определение индекса бара, с которого необходимо производить перерасчет              |
//+-------------------------------------------------------------------------------------+
int GetRecalcIndex(int& total)
{
   static int lastBarsCnt;                         // Определение первого бара истории,..
   if (g_init)                                     // ..на котором будут доступны..
   {                                               // ..адекватные значения
      lastBarsCnt = 0;
      g_init = false;
   }
   total = Bars - 2;                               
                                                   
    
   if (i_indBarsCount > 0 && i_indBarsCount < total)// Если не нужно рассчитывать всю..
      total = i_indBarsCount;                      // ..историю, то начнем с указанного..
                                                   // ..бара
   if (lastBarsCnt < Bars - 1)                     // Кол-во посчитанных баров - 0. Будут
   {                                               // ..удалены все графические объекты
      lastBarsCnt = Bars;
      DeleteAllObjects();                          
      return (total);                              // Если вся история - то total
   }
   
   int newBarsCnt = Bars - lastBarsCnt;
   lastBarsCnt = Bars;
   return (newBarsCnt);                            // Начинаем с нового бара
}
//+-------------------------------------------------------------------------------------+
//| Отображение трендовой линии                                                         |
//+-------------------------------------------------------------------------------------+
void ShowTrendLine(int index, datetime leftTime, double leftPrice, datetime rightTime,
                   color clr)
{
   string name = PREFIX + SIGN_TREND_LINE + leftTime + index;

   if (ObjectFind(name) < 0)
   {
      ObjectCreate(name, OBJ_TREND, 0, leftTime, leftPrice, rightTime, leftPrice);
      ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(name, OBJPROP_COLOR, clr);
      ObjectSet(name, OBJPROP_BACK, true);
      ObjectSet(name, OBJPROP_RAY, false);
      return;
   }
   
   ObjectMove(name, 0, leftTime, leftPrice);
   ObjectMove(name, 1, rightTime, leftPrice);
   ObjectSet(name, OBJPROP_COLOR, clr);
}
//+-------------------------------------------------------------------------------------+
//| Определение экстремумов указанного дня  и перераспределение массива объемов при..   |
//| ..необходимости                                                                     |
//+-------------------------------------------------------------------------------------+
int GetDayVolatility(int leftIndex, int rightIndex, int& volumesArray[], 
                     double& minDayPrice)
{
   int barsPerDay = leftIndex - rightIndex + 1;
   
   minDayPrice = iLow(NULL, PERIOD_M1, 
                      iLowest(NULL, PERIOD_M1, MODE_LOW, barsPerDay, rightIndex));
   double maxDayPrice = iHigh(NULL, PERIOD_M1, 
                              iHighest(NULL, PERIOD_M1, MODE_HIGH, 
                                       barsPerDay, rightIndex));
                                       
   int dayVolatility = MathRound((maxDayPrice - minDayPrice + Point) / Point);
   if (dayVolatility > MAX_DAY_VOLATILITY)
      ArrayResize(volumesArray, dayVolatility);
   
   ArrayInitialize(volumesArray, 0);   
   return (dayVolatility);
}
//+-------------------------------------------------------------------------------------+
//| Запись уровней одной свечи в массив объемов                                         |
//+-------------------------------------------------------------------------------------+
void SaveVolumes(double minBarPrice, double maxBarPrice, double minDayPrice,
                 double volume, int& volumesArray[], int& maxVolume, 
                 double& maxVolumePrice)
{
   for (double price = minBarPrice; 
        IsFirstMoreOrEqualThanSecond(maxBarPrice, price); 
        price += Point)
   {
      int indexOfArray = MathRound((price - minDayPrice) / Point);
      volumesArray[indexOfArray] += volume;
      if (maxVolume < volumesArray[indexOfArray])
      {
         maxVolume = volumesArray[indexOfArray];
         maxVolumePrice = price;
      }
   }
}
//+-------------------------------------------------------------------------------------+
//| Формирование массивов объемов и соответствующих им индексов баров                   |
//+-------------------------------------------------------------------------------------+
void FormVolumesArray(int leftIndex, int rightIndex, int& volumesArray[], 
                      int& dayVolatility, double& minDayPrice, int& maxVolume, 
                      double& maxVolumePrice)
{
   dayVolatility = GetDayVolatility(leftIndex, rightIndex, volumesArray, minDayPrice);
   maxVolume = 0;

   for (int i = leftIndex; i >= rightIndex; i--)
   {
      double minBarPrice = iLow(NULL, PERIOD_M1, i); 
      double maxBarPrice = iHigh(NULL, PERIOD_M1, i); 
      if (IsValuesEquals(minBarPrice, maxBarPrice))
         continue;

      int volume = iVolume(NULL, PERIOD_M1, i);
      SaveVolumes(minBarPrice, maxBarPrice, minDayPrice, volume, 
                  volumesArray, maxVolume, maxVolumePrice);
   }
}
//+-------------------------------------------------------------------------------------+
//| Вычисление индексов баров минутного ТФ, ограничивающих день перед указанным временем|
//+-------------------------------------------------------------------------------------+
int GetIndexesOfDayRange(datetime timeOfNextDay, int& endDayBar, bool isNewDay)
{
   endDayBar = 0;
   if (isNewDay)
      endDayBar = iBarShift(NULL, PERIOD_M1, timeOfNextDay) + 1;
   int beginDayBar = endDayBar;
   int total = iBars(NULL, PERIOD_M1);

   while (TimeDayOfYear(iTime(NULL, PERIOD_M1, beginDayBar)) == 
          TimeDayOfYear(iTime(NULL, PERIOD_M1, endDayBar))
          &&
          beginDayBar < total)
      beginDayBar++;
      
   return (beginDayBar - 1);
}
//+-------------------------------------------------------------------------------------+
//| Больше или равно первое число, чем второе?                                          |
//+-------------------------------------------------------------------------------------+
bool IsFirstMoreOrEqualThanSecond(double first, double second)
{
   return (first - second > - Point / 100);
}
//+-------------------------------------------------------------------------------------+
//| Первое число больше чем второе (first > second)?                                    |
//+-------------------------------------------------------------------------------------+
bool IsFirstMoreThanSecond(double first, double second)
{
   return (first - second > Point / 1000);
}
//+-------------------------------------------------------------------------------------+
//| Значения равны?                                                                     |
//+-------------------------------------------------------------------------------------+
bool IsValuesEquals(double first, double second)
{
   return (MathAbs(first - second) < Point / 1000);
}
//+-------------------------------------------------------------------------------------+
//| Определение цвета гистограммы                                                       |
//+-------------------------------------------------------------------------------------+
color GetHistogrammColor(double maxVolumePrice, int endDayBar)
{
   double dayClosePrice = iClose(NULL, PERIOD_M1, endDayBar);
   
   if (IsValuesEquals(maxVolumePrice, dayClosePrice))
      return (i_indefiniteColor);
      
   if (IsFirstMoreThanSecond(maxVolumePrice, dayClosePrice))
      return (i_resistanceColor);
      
   return (i_supportColor);
}
//+-------------------------------------------------------------------------------------+
//| Отображение найденных уровней                                                       |
//+-------------------------------------------------------------------------------------+
void ShowLevels(int dayVolatility, int& volumesArray[], double minDayPrice, 
                datetime dayBeginTime, int endDayBar, int maxVolume, 
                double maxVolumePrice)
{
   // Определение количества секунд, приходящегося на единичный тиковый объем
   double secondsInDay = MathMax(1, 
                                 iTime(NULL, PERIOD_M1, endDayBar) - dayBeginTime + 60);

   double secondsPerVolume = secondsInDay / maxVolume;
   
   // Определение цвета гистограммы
   color showColor = GetHistogrammColor(maxVolumePrice, endDayBar);

   // Отображение гистограммы   
   for (int i = 0; i < dayVolatility; i++)
   {
      double price = minDayPrice + i * Point;
      datetime volume = dayBeginTime + MathRound(secondsPerVolume * volumesArray[i]);
      ShowTrendLine(i, dayBeginTime, price, volume, showColor);  
   }
}
//+-------------------------------------------------------------------------------------+
//| Обработка одного заданного бара                                                     |
//+-------------------------------------------------------------------------------------+
void ProcessOneCandle(int index)
{
   // Если нет перехода через начало суток, то свеча не обрабатывается
   datetime timeOfBar = Time[index];
   datetime prevBarTime = Time[index + 1];
   if (TimeDayOfYear(timeOfBar) == TimeDayOfYear(prevBarTime) && index != 0)
      return;
      
   // Нахождение бара и времени начала дня  
   int endDayBar;
   int beginDayBar = GetIndexesOfDayRange(timeOfBar, endDayBar, index != 0);   
   datetime dayBeginTime = iTime(NULL, PERIOD_M1, beginDayBar);
      
   // Формирование массива данных для расчета статпараметров на их основе
   double minDayPrice, maxVolumePrice;
   int maxVolume, dayVolatility;
   FormVolumesArray(beginDayBar, endDayBar, g_volumesArray, 
                    dayVolatility, minDayPrice, maxVolume, maxVolumePrice);
   if (maxVolume == 0)
      return;                    
   
   // Отображение уровней
   ShowLevels(dayVolatility, g_volumesArray, minDayPrice, 
              dayBeginTime, endDayBar, maxVolume, maxVolumePrice);
}
//+-------------------------------------------------------------------------------------+
//| Отображение данных индикатора                                                       |
//+-------------------------------------------------------------------------------------+
void ShowIndicatorData(int limit, int total)
{
   for (int i = limit; i >= 0; i--)
      ProcessOneCandle(i);
}
//+-------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                 |
//+-------------------------------------------------------------------------------------+
int start()
{
   if (!g_activate)                                // Если индикатор не прошел..
      return (0);                                  // ..инициализацию, то работать он..
                                                   // ..не должен
                                                   
   if (!IsAllBarsAvailable(PERIOD_M1))             // Проверка готовности данных на ТФ М1
      return (0);
                                                   
   int total;   
   int limit = GetRecalcIndex(total);              // С какого бара начинать обновление

   ShowIndicatorData(limit, total);                // Отображение данных индикатора
   
   WindowRedraw();

   return(0);
}