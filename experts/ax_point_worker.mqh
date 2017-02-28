//+------------------------------------------------------------------+
//|                                              ax_point_worker.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property strict

//+------------------------------------------------------------------+
enum point_calc
{
 POINTCALC_NONE,
 POINTCALC_NORMALIZED
};

//+------------------------------------------------------------------+
class ax_point_worker
{
 private:
  const double m_lot;
 
 public:
  ax_point_worker(double lot);
  
  double get_points(double cost,point_calc pc=POINTCALC_NORMALIZED);
  double get_cost(double points,point_calc pc=POINTCALC_NORMALIZED);
  
 private:
  double get_point_cost();
  double get_point_cost_via_lot();
};

//+------------------------------------------------------------------+
ax_point_worker::ax_point_worker(double lot)
 :m_lot(lot)
{
}

//+------------------------------------------------------------------+
double ax_point_worker::get_points(double cost,point_calc pc)
{
 double tmp=cost/this.get_point_cost_via_lot();
 
 if(pc==POINTCALC_NORMALIZED)
  return NormalizeDouble(tmp/MathPow(10,Digits),Digits);
  
 return NormalizeDouble(cost/this.get_point_cost_via_lot(),0);
}

//+------------------------------------------------------------------+
double ax_point_worker::get_cost(double points,point_calc pc)
{
 return NormalizeDouble(points*(pc==POINTCALC_NORMALIZED?MathPow(10,Digits):1)*this.get_point_cost_via_lot(),2);
}

//+------------------------------------------------------------------+
double ax_point_worker::get_point_cost()
{
 string __sym=Symbol();
 
 return MarketInfo(__sym,MODE_TICKVALUE)*(MarketInfo(__sym,MODE_POINT)/MarketInfo(__sym,MODE_TICKSIZE));
}

//+------------------------------------------------------------------+
double ax_point_worker::get_point_cost_via_lot()
{
 return this.get_point_cost()*this.m_lot;
}

//+------------------------------------------------------------------+

