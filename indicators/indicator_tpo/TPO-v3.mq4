#property copyright "TPO: Time Price Opportunity v3.0. Copyright © FXcoder, 2009-2014"
#property link      "http://fxcoder.ru"
#property strict
#property indicator_chart_window

enum ENUM_TPO_PERIOD {
	TPO_PERIOD_M1 = PERIOD_M1,   // M1 (1 minute)
	TPO_PERIOD_M5 = PERIOD_M5,   // M5 (5 minutes)
	TPO_PERIOD_M15 = PERIOD_M15, // M15 (15 minutes)
	TPO_PERIOD_M30 = PERIOD_M30, // M30 (30 minutes)
	TPO_PERIOD_H1 = PERIOD_H1,   // H1 (1 hour)
	TPO_PERIOD_H4 = PERIOD_H4,   // H4 (4 hours)
	TPO_PERIOD_D1 = PERIOD_D1,   // D1 (1 day)
	TPO_PERIOD_W1 = PERIOD_W1,   // W1 (1 week)
	TPO_PERIOD_MN1 = PERIOD_MN1  // MN1 (1 month)
};

enum ENUM_TPO_HG_STYLE {
	TPO_HG_STYLE_LINES = 0,             // Lines
	TPO_HG_STYLE_EMPTY_RECTANGLES = 1,  // Empty rectangles
	TPO_HG_STYLE_FILLED_RECTANGLES = 2  // Filled rectangles
};

enum ENUM_TPO_VOLUME_TYPE {
	TPO_VOLUME_TYPE_TICK = 1,  // Tick volume
	TPO_VOLUME_TYPE_REAL = 2   // Real volume
};

/* Параметры расчетов */
// ТФ диапазона, должен быть одним из стандартных
extern ENUM_TPO_PERIOD RangePeriod = TPO_PERIOD_D1; // Range period

// количество диапазонов/гистограмм
extern int RangeCount = 20; // Range count

// шаг поиска мод, фактически в 2 раза больше + 1
extern int ModeStep = 10; // Mode step (points)

// глубина сглаживания, применяется алгоритм последовательного усреднения триад указанное число раз
int Smooth = 0;

// шаг цены, 0 - авто (см. #1)
int PriceStep = 0;

// период для данных, минутки - самые точные
ENUM_TPO_PERIOD DataPeriod = TPO_PERIOD_M1;

// тип объема для расчета
extern ENUM_TPO_VOLUME_TYPE VolumeType = TPO_VOLUME_TYPE_TICK; // Volume type

// показать горизонт данных
bool ShowHorizon = true;

/* Гистограмма */
// цвет гистограммы
extern color HGColor = C'160,192,224'; // Histogram color (None=disable)

// стиль гистограммы: 0 - линии, 1 - пустые прямоугольники, 2 - заполненные прямоугольники
extern ENUM_TPO_HG_STYLE HGStyle = TPO_HG_STYLE_EMPTY_RECTANGLES; // Histogram bar style

// цвет мод
extern color ModeColor = Blue; // Mode color (None=disable)

// выделить максимум
extern color MaxModeColor = CLR_NONE; // Mode color (maximum volume, None=disable)

// ширина линий гистограммы
int HGLineWidth = 1;

// масштаб гистограммы, 0 - автомасштаб
double Zoom = 0;

// толщина мод
int ModeWidth = 1;

// стиль мод
ENUM_LINE_STYLE ModeStyle = STYLE_SOLID;

/* Служебные */
// префикс имен линий
extern string Id = "+tpo"; // Identifier

// минимальное время, в секундах, между обновлениями
int WaitSeconds = 1;

string _onp;

datetime _drawHistory[];  // история рисования
datetime _lastTime = 0;   // последнее времся запуска
bool _lastOK = false;

double _hgPoint;          // минимальное изменение цены
int _modeStep = 0;

bool _showHG, _showModes, _showMaxMode;
bool _hgBack = true;
bool _hgUseRectangles = false;

int init()
{
	_onp = Id + " " + IntegerToString(RangePeriod) + " ";

	_hgPoint = Point;

	bool is5digits = ((Digits == 3) || (Digits == 5)) && (MarketInfo(Symbol(), MODE_PROFITCALCMODE) == 0);

	//#1
	if (PriceStep == 0)
	{
		if (is5digits)
			_hgPoint = Point * 10.0;
	}
	else
	{
		_hgPoint = Point * PriceStep;
	}

	if (is5digits)
		_modeStep = (int)(10 * ModeStep * Point / _hgPoint);
	else
		_modeStep = (int)(ModeStep * Point / _hgPoint);

	ArrayResize(_drawHistory, 0);

	// настройки отображения
	_showHG = !ColorIsNone(HGColor);
	_showModes = !ColorIsNone(ModeColor);
	_showMaxMode = !ColorIsNone(MaxModeColor);

	// корректируем параметры стиля
	if (HGStyle == TPO_HG_STYLE_EMPTY_RECTANGLES)
	{
		_hgBack = false;
		_hgUseRectangles = true;
	}
	else if (HGStyle == TPO_HG_STYLE_FILLED_RECTANGLES)
	{
		_hgBack = true;
		_hgUseRectangles = true;
	}

	return(0);
}

int start()
{
	datetime currentTime = TimeLocal();

	// всегда обновляемся на новом баре...
	if ((Volume[0] > 1) && _lastOK)
	{
		// ...и не чаще, чем раз в несколько секунд
		if (currentTime - _lastTime < WaitSeconds)
			return(0);
	}

	_lastTime = currentTime;

	if (ShowHorizon)
	{
		datetime hz = iTime(NULL, DataPeriod, iBars(NULL, DataPeriod) - 1);
		drawVLine(_onp + "hz", hz, Red, 1, STYLE_DOT, false);
	}

	double vh[], hLow;

	_lastOK = true;

	for (int i = 0; i < RangeCount; i++)
	{
		int barFrom, barTo, m1BarFrom, m1BarTo;
		datetime timeFrom = iTime(NULL, RangePeriod, i);
		datetime timeTo = Time[0];

		if (i != 0)
			timeTo = iTime(NULL, RangePeriod, i - 1);

		if (getRange(timeFrom, timeTo, barFrom, barTo, m1BarFrom, m1BarTo, DataPeriod))
		{
			if (!checkDrawHistory(timeFrom) || (i == 0))
			{
				int count = getHGByRates(m1BarFrom, m1BarTo, vh, hLow, _hgPoint, DataPeriod, VolumeType);

				if (count > 0)
				{
					if (Smooth > 0)
						count = smoothHG(vh, Smooth);

					if (i != 0)
						addDrawHistory(timeFrom);

					// определение масштаба
					double zoom = Zoom * 0.000001;

					if (zoom <= 0)
					{
						double maxVolume = vh[ArrayMaximum(vh)];
						zoom = (barFrom - barTo) / maxVolume;
					}

					// рисуем
					if (_showHG)
					{
						string prefix = _onp + "hg " + TimeToStr(timeFrom) + " ";
						drawHG(prefix, vh, hLow, barFrom, HGColor, HGColor, zoom, HGLineWidth, _hgPoint);
					}

					if (_showModes || _showMaxMode)
					{
						// поиск мод
						int modes[];
						int modeCount = getModes(vh, _modeStep, modes);

						drawModes(vh, hLow, modes, barFrom, zoom, _hgPoint);
					}
				}
			}
		}
		else
		{
			_lastOK = false;
		}
	}

	return(0);
}

int deinit()
{
	clearChart(_onp);
	return(0);
}

// проверяет, рисовались ли для данной даты уровни
bool checkDrawHistory(datetime time)
{
	for (int i = 0, count = ArraySize(_drawHistory); i < count; i++)
	{
		if (_drawHistory[i] == time)
		    return(true);
	}

	return(false);
}

// добавить отрисованный участок в историю
void addDrawHistory(datetime time)
{
	if (!checkDrawHistory(time))
	{
		int count = ArraySize(_drawHistory);
		ArrayResize(_drawHistory, count + 1);
		_drawHistory[count] = time;
	}
}

#import "gdi32.dll"
uint GetPixel(int hDC, int x, int y);
#import

int IntPutInRange(int value, int from, int to)
{
	if (to >= from)
	{
		if (value > to)
			value = to;
		else if (value < from)
			value = from;
	}

	return(value);
}

double DoublePutInRange(double value, double from, double to)
{
	if (to >= from)
	{
		if (value > to)
			value = to;
		else if (value < from)
			value = from;
	}

	return(value);
}

bool ColorToRGB(color c, int& r, int& g, int& b)
{
	// Если цвет задан неверный, либо задан как отсутствующий, вернуть false
	if ((c >> 24) > 0)
	{
		r = 255;
		g = 255;
		b = 255;
		return(false);
	}

	// 0x00BBGGRR
	b = (c & 0xFF0000) >> 16;
	g = (c & 0x00FF00) >> 8;
	r = (c & 0x0000FF);

	return(true);
}

color RGBToColor(int r, int g, int b)
{
	// 0x00BBGGRR
	return((color)(
	    ((b & 0x0000FF) << 16) + ((g & 0x0000FF) << 8) + (r & 0x0000FF)
	    ));
}

color MixColors(color color1, color color2, double mix, double step = 16)
{
	// Коррекция параметров
	step = DoublePutInRange(step, 1.0, 255.0);
	mix = DoublePutInRange(mix, 0.0, 1.0);

	int r1, g1, b1;
	int r2, g2, b2;

	// Разбить на компоненты
	ColorToRGB(color1, r1, g1, b1);
	ColorToRGB(color2, r2, g2, b2);

	// вычислить
	int r = IntPutInRange((int)(MathRound((r1 + mix * (r2 - r1)) / step) * step), 0, 255);
	int g = IntPutInRange((int)(MathRound((g1 + mix * (g2 - g1)) / step) * step), 0, 255);
	int b = IntPutInRange((int)(MathRound((b1 + mix * (b2 - b1)) / step) * step), 0, 255);

	return(RGBToColor(r, g, b));
}

bool ColorIsNone(color c)
{
	return((c >> 24) > 0);
}

#define ERR_HISTORY_WILL_UPDATED 4066

// получить время по номеру бара с учетом возможного выхода за диапазон баров (номер бара меньше 0)
datetime getBarTime(int shift, int period = 0)
{
	if (period == 0)
		period = Period();

	if (shift >= 0)
		return(iTime(Symbol(), period, shift));
	else
		return(iTime(Symbol(), period, 0) - shift*period*60);
}

// Очистить график от своих объектов
int clearChart(string prefix)
{
	int count = 0;

	for (int i = ObjectsTotal() - 1; i >= 0; i--)
	{
		string name = ObjectName(i);

		if (StringFind(name, prefix) == 0)
		{
			ObjectDelete(name);
			count++;
		}
	}

	return(count);
}

void drawVLine(string name, datetime time1, color lineColor = Gray, int width = 1, int style = STYLE_SOLID, bool back = true)
{
	if (ObjectFind(name) >= 0)
		ObjectDelete(name);

	ObjectCreate(name, OBJ_VLINE, 0, time1, 0);
	ObjectSet(name, OBJPROP_COLOR, lineColor);
	ObjectSet(name, OBJPROP_BACK, back);
	ObjectSet(name, OBJPROP_STYLE, style);
	ObjectSet(name, OBJPROP_WIDTH, width);
}

void drawBar(string name, datetime time1, double price1, datetime timeTo, double price2,
	color lineColor, int width, int style, bool back, bool ray, int window, bool useRectangle,
	double hgPoint)
{
	if (ObjectFind(name) >= 0)
		ObjectDelete(name);

	// если рисовать прямоугольниками, то при наложении они не смешиваются
	if (useRectangle)
		ObjectCreate(name, OBJ_RECTANGLE, window, time1, price1 - hgPoint / 2.0, timeTo, price2 + hgPoint / 2.0);
	else
		ObjectCreate(name, OBJ_TREND, window, time1, price1, timeTo, price2);

	ObjectSet(name, OBJPROP_BACK, back);
	ObjectSet(name, OBJPROP_COLOR, lineColor);
	ObjectSet(name, OBJPROP_STYLE, style);
	ObjectSet(name, OBJPROP_WIDTH, width);
	ObjectSet(name, OBJPROP_RAY, ray);

	ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
	ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

// нарисовать гистограмму (+цвет +point)
void drawHG(string prefix, double& h[], double low, int barFrom, color bgColor, color lineColor, double zoom, int width, double point)
{
	double max = h[ArrayMaximum(h)];

	if (max == 0)
		return;

	int bgR, bgG, bgB;
    if (!ColorToRGB(bgColor, bgR, bgG, bgB))
        return;

	int lineR, lineG, lineB;
    if (!ColorToRGB(lineColor, lineR, lineG, lineB))
        return;

	int dR = lineR - bgR;
	int dG = lineG - bgG;
	int dB = lineB - bgB;

	for (int i = 0, hc = ArraySize(h); i < hc; i++)
	{
		double price = NormalizeDouble(low + i * point, Digits);

		int barTo = (int)(barFrom - h[i] * zoom);

		// раскраска градиентом
		color cl = MixColors(bgColor, lineColor, h[i] / max);

		datetime timeFrom = getBarTime(barFrom);
		datetime timeTo = getBarTime(barTo);

		if (barFrom != barTo)
			drawBar(prefix + DoubleToStr(price, Digits), timeFrom, price, timeTo, price, cl, width, STYLE_SOLID, _hgBack, false, 0, _hgUseRectangles, point);
	}
}

// получить параметры диапазона
bool getRange(datetime timeFrom, datetime timeTo, int& barFrom, int& barTo, int& p1BarFrom, int& p1BarTo, int period)
{
	// диапазон баров в текущем ТФ (для рисования)

	barFrom = iBarShift(NULL, 0, timeFrom);
	datetime time = Time[barFrom];
	int bar = iBarShift(NULL, 0, time);
	time = Time[bar];

	if (time != timeFrom)
		barFrom--;

	barTo = iBarShift(NULL, 0, timeTo);
	time = Time[barTo];
	bar = iBarShift(NULL, 0, time);
	time = Time[bar];

	if (time == timeFrom)
		barTo++;

	if (barFrom < barTo)
		return(false);

	// диапазон баров ТФ period (для получения данных)

	p1BarFrom = iBarShift(NULL, period, timeFrom);
	time = iTime(NULL, period, p1BarFrom);

	if (time != timeFrom)
		p1BarFrom--;

	p1BarTo = iBarShift(NULL, period, timeTo);
	time = iTime(NULL, period, p1BarTo);

	if (timeTo == time)
		p1BarTo++;

	if (p1BarFrom < p1BarTo)
		return(false);

	return(true);
}

// Получить гистограмму распределения цен
//		m1BarFrom, m1BarTo - границы диапазона, заданные номерами баров минуток
// Возвращает:
//		результат - количество цен в гистограмме, 0 - ошибка
//		vh - гистограмма
//		hLow - нижняя граница гистограммы
//		point - шаг цены
//		dataPeriod - таймфрейм данных
int getHGByRates(int m1BarFrom, int m1BarTo, double& vh[], double& hLow, double point, int dataPeriod, ENUM_TPO_VOLUME_TYPE volumeType)
{
	MqlRates rates[];
	double hHigh;

	// предположительное (и максимальное) количество минуток
	int rCount = getRates(m1BarFrom, m1BarTo, rates, hLow, hHigh, dataPeriod);

	if (rCount == 0)
	    return(0);

	hLow = NormalizeDouble(MathRound(hLow / point) * point, Digits);
	hHigh = NormalizeDouble(MathRound(hHigh / point) * point, Digits);

	// инициализируем массив гистограммы
	int hCount = (int)(MathRound(hHigh / point) - MathRound(hLow / point) + 1);
	ArrayResize(vh, hCount);
	ArrayInitialize(vh, 0);

	int iCount = m1BarFrom - m1BarTo + 1;
	int hc = calcHGByRates(rates, rCount, iCount, m1BarTo, point, hLow, hCount, vh, volumeType);

	if (hc == hCount)
		return(hc);

	return(0);
}

// Получить гистограмму распределения цен
int calcHGByRates(MqlRates& rates[], int rcount, int icount, int ishift, double point, double hLow, int hCount, double& vh[], ENUM_TPO_VOLUME_TYPE volumeType)
{
	int pri;   // индекс цены
	double dv; // объем на тик

	int hLowI = (int)MathRound(hLow / point);

	for (int j = 0; j < icount; j++)
	{
		int i = j + ishift;

		double o = rates[i].open;
		int oi = (int)MathRound(o / point);

		double h = rates[i].high;
		int hi = (int)MathRound(h / point);

		double l = rates[i].low;
		int li = (int)MathRound(l / point);

		double c = rates[i].close;
		int ci = (int)MathRound(c / point);

		long v = volumeType == TPO_VOLUME_TYPE_REAL ? rates[i].real_volume : rates[i].tick_volume;

		// при нулевом объеме прекратить расчет
		if (v == 0)
			return 0;

		int rangeMin = hLowI;
		int rangeMax = hLowI + hCount - 1;

		// имитация тиков
		if (c >= o)     // бычья свеча
		{
			dv = v / (oi - li + hi - li + hi - ci + 1.0);

			for (pri = oi; pri >= li; pri--)        // open --> low
				vh[pri - hLowI] += dv;

			for (pri = li + 1; pri <= hi; pri++)    // low+1 ++> high
				vh[pri - hLowI] += dv;

			for (pri = hi - 1; pri >= ci; pri--)    // high-1 --> close
				vh[pri - hLowI] += dv;
		}
		else            // медвежья свеча
		{
			dv = v / (hi - oi + hi - li + ci - li + 1.0);

			for (pri = oi; pri <= hi; pri++)        // open ++> high
				vh[pri - hLowI] += dv;

			for (pri = hi - 1; pri >= li; pri--)    // high-1 --> low
				vh[pri - hLowI] += dv;

			for (pri = li + 1; pri <= ci; pri++)    // low+1 ++> close
				vh[pri - hLowI] += dv;
		}
	}

	return(hCount);
}

// Получить моды на основе гистограммы и сглаженной гистограммы (быстрый метод, без сглаживания)
int getModes(double& vh[], int modeStep, int& modes[])
{
	int modeCount = 0;
	ArrayFree(modes);

	// ищем максимумы по участкам
	for (int i = modeStep, count = ArraySize(vh); i < count - modeStep; i++)
	{
		int maxFrom = i - modeStep;
		int maxRange = 2 * modeStep + 1;
		int maxTo = maxFrom + maxRange - 1;

		int k = ArrayMaximum(vh, maxRange, maxFrom);

		if (k == i)
		{
			for (int j = i - modeStep; j <= i + modeStep; j++)
			{
				if (vh[j] == vh[k])
				{
					modeCount++;
					ArrayResize(modes, modeCount);
					modes[modeCount-1] = j;
				}
			}
		}

	}

	return(modeCount);
}

// Получить минутки для заданного диапазона (указывается в номерах баров минуток)
int getRates(int barFrom, int barTo, MqlRates& rates[], double& ilowest, double& ihighest, int period)
{
	// предположительное (и максимальное) количество минуток
	int iCount = barFrom - barTo + 1;
	int count = ArrayCopyRates(rates, NULL, period);

	if (GetLastError() == ERR_HISTORY_WILL_UPDATED)
		return(0);

	if (count < barFrom - 1)
	    return(0);

	ilowest = iLow(NULL, period, iLowest(NULL, period, MODE_LOW, iCount, barTo));
	ihighest = iHigh(NULL, period, iHighest(NULL, period, MODE_HIGH, iCount, barTo));
	return(count);
}

int smoothHG(double& vh[], int depth)
{
	int vCount = ArraySize(vh);

	if (depth == 0)
		return(vCount);

	// расширяем массив (необходимо для корректных расчетов)
	int newCount = vCount + 2 * depth;

	// сдвигаем значения и зануляем хвосты
	double th[];
	ArrayResize(th, newCount);
	ArrayInitialize(th, 0);

	ArrayCopy(th, vh, depth, 0);

	ArrayResize(vh, newCount);
	ArrayInitialize(vh, 0);

	// последовательное усреднение
	for (int d = 0; d < depth; d++)
	{
		for (int i = -d; i < vCount + d; i++)
			vh[i+depth] = (th[i+depth-1] + th[i+depth] + th[i+depth+1]) / 3.0;

		ArrayCopy(th, vh);
	}

	ArrayResize(vh, vCount);
	ArrayCopy(vh, th, 0, depth, vCount);

	return(newCount);
}

// нарисовать моды гистограммы
void drawModes(double& vh[], double hLow, int& modes[], int barFrom, double zoom, double point)
{
	int modeCount = ArraySize(modes);
	int j;
	double price;

	// макс. мода
	double max = 0;

	if (_showMaxMode)
	{
		for (j = 0; j < modeCount; j++)
		{
			if (vh[modes[j]] > max)
				max = vh[modes[j]];
		}
	}

	datetime timeFrom = getBarTime(barFrom);

	string namePrefix = _onp + "mode " + TimeToStr(timeFrom) + " ";

	// удалить старые моды и их уровни, они могут менять положение
	clearChart(namePrefix);

	bool back = _hgUseRectangles;
	string on;

	for (j = 0; j < modeCount; j++)
	{
		double v = zoom * vh[modes[j]];

		// не рисовать коротких линий (меньше бара ТФ), глючит при выделении границ
		if (MathAbs(v) > 0)
		{
			price = hLow + modes[j] * point;
			datetime timeTo = getBarTime((int)(barFrom - v));

			on = _onp + namePrefix + DoubleToStr(price, Digits);

			if (_showMaxMode && (MathAbs(vh[modes[j]] - max) < point))	// максимальная мода
			{
				drawBar(on, timeFrom, price, timeTo, price, MaxModeColor, ModeWidth, ModeStyle, back, false, 0, _hgUseRectangles, point);

				// в режиме рисования прямоугольниками моды рисуем линиями, иначе они скрываются
				if (_hgUseRectangles && back)
					drawBar(on + "+", timeFrom, price, timeTo, price, MaxModeColor, ModeWidth, ModeStyle, false, false, 0, false, point);
			}
			else if (_showModes)	// обычная мода
			{
				drawBar(on, timeFrom, price, timeTo, price, ModeColor, ModeWidth, ModeStyle, back, false, 0, _hgUseRectangles, point);

				// в режиме рисования прямоугольниками моды рисуем линиями, иначе они скрываются
				if (_hgUseRectangles && back)
					drawBar(on + "+", timeFrom, price, timeTo, price, ModeColor, ModeWidth, ModeStyle, false, false, 0, false, point);
			}
		}
	}
}

// 2014-02-22 01:05:04 UTC
// MQLMake 1.20. Copyright © FXcoder, 2011-2014. http://fxcoder.ru