//+------------------------------------------------------------------+
//|                                                ax_mfi_worker.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property strict

enum t_mfiworkmode
{
 MFIWORKMODE_MFI,//только BW MFI
 MFIWORKMODE_AXMFI,//только AX MFI
 MFIWORKMODE_MFIANDAXMFI,//BW MFI и AX MFI
 MFIWORKMODE_MFIORAXMFI//BW MFI или AX MFI
};

class ax_mfi_worker
{
 private:
  t_mfiworkmode m_workmode;
  
 public:
  void init(t_mfiworkmode wm);
  
  bool value(MqlRates& rates[],int shift,t_mfivalue indival);
  
 private:
  t_mfivalue get_bwmfival(MqlRates& rates[],int shift);
  t_mfivalue get_axmfival(MqlRates& rates[],int shift);
  t_mfivalue get_val(double mfi,double prev_mfi,long v,long prev_v);
};

//+------------------------------------------------------------------+
void ax_mfi_worker::init(t_mfiworkmode wm)
{
 this.m_workmode=wm;
}

//+------------------------------------------------------------------+
bool ax_mfi_worker::value(MqlRates& rates[],int shift,t_mfivalue indival)
{
 if(this.m_workmode==MFIWORKMODE_MFI)
  return this.get_bwmfival(rates,shift)==indival;
  
 if(this.m_workmode==MFIWORKMODE_AXMFI)
  return this.get_axmfival(rates,shift)==indival;
  
 if(this.m_workmode==MFIWORKMODE_MFIANDAXMFI)
  return this.get_bwmfival(rates,shift)==indival && this.get_axmfival(rates,shift)==indival;
  
 return this.get_bwmfival(rates,shift)==indival || this.get_axmfival(rates,shift)==indival;
}

//+------------------------------------------------------------------+
t_mfivalue ax_mfi_worker::get_bwmfival(MqlRates& rates[],int shift)
{
 double mfi      =(rates[shift].high-rates[shift].low)/rates[shift].tick_volume/_Point;
 double prev_mfi =(rates[shift+1].high-rates[shift+1].low)/rates[shift+1].tick_volume/_Point;
 
 return this.get_val(mfi,prev_mfi,rates[shift].tick_volume,rates[shift+1].tick_volume);
}

//+------------------------------------------------------------------+
t_mfivalue ax_mfi_worker::get_axmfival(MqlRates& rates[],int shift)
{
 double gator       =iAlligator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,shift);
 double prev_gator  =iAlligator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,shift+1);
 
 double median      =(rates[shift].high+rates[shift].low)/2;
 double prev_median =(rates[shift+1].high+rates[shift+1].low)/2;
 
 double mfi      =MathAbs(median-gator)/rates[shift].tick_volume/_Point;
 double prev_mfi =MathAbs(prev_median-prev_gator)/rates[shift+1].tick_volume/_Point;
 
 return this.get_val(mfi,prev_mfi,rates[shift].tick_volume,rates[shift+1].tick_volume);
}

//+------------------------------------------------------------------+
t_mfivalue ax_mfi_worker::get_val(double mfi,double prev_mfi,long v,long prev_v)
{
 if(mfi>prev_mfi && v>prev_v)
  return MFIVALUE_GREEN;
  
 if(mfi<prev_mfi && v>prev_v)
  return MFIVALUE_PINK;
  
 if(mfi>prev_mfi && v<prev_v)
  return MFIVALUE_BLUE;
  
 return MFIVALUE_BROWN;
}

//+------------------------------------------------------------------+
