#ifndef __TFCONTEXT_MQH__
#define __TFCONTEXT_MQH__

#include "Logging.mqh"

//==============================================================
//   Структура контекста таймфрейма
//==============================================================
struct TFContext
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   bool ok;
   datetime lastBarTime;

   int hADX, hATR, hSTD, hEMA;
   double adx, atr, std, ema, slope;
   double ema_prev;
};

// безопасное чтение последнего значения буфера
bool ReadLast(const int handle, const int buffer, double &out)
{
   if(handle==INVALID_HANDLE) return false;
   double tmp[];
   int copied = CopyBuffer(handle, buffer, 0, 2, tmp);
   if(copied<=0) return false;
   out = tmp[0];
   return true;
}

// инициализация контекста
bool TFContextInit(TFContext &c, const string symbol, const ENUM_TIMEFRAMES tf)
{
   ZeroMemory(c);
   c.symbol = symbol;
   c.tf     = tf;
   c.ok     = false;

   c.hADX = iADX(symbol, tf, 14);
   c.hATR = iATR(symbol, tf, 14);
   c.hSTD = iStdDev(symbol, tf, 20, 0, MODE_SMA, PRICE_CLOSE);
   c.hEMA = iMA(symbol, tf, 50, 0, MODE_EMA, PRICE_CLOSE);

   if(c.hADX==INVALID_HANDLE || c.hATR==INVALID_HANDLE || c.hSTD==INVALID_HANDLE || c.hEMA==INVALID_HANDLE)
   { LErr("TFContextInit: invalid handles"); return false; }

   double ema_now=0.0, ema_old=0.0;
   {
      double arr[];
      int copied = CopyBuffer(c.hEMA, 0, 0, 2, arr);
      if(copied<2){ LWarn("TFContextInit: EMA warmup failed"); }
      ema_now= (copied>0?arr[0]:0); ema_old=(copied>1?arr[1]:ema_now);
   }
   c.ema       = ema_now;
   c.ema_prev  = ema_old;
   c.slope     = 0.0;
   c.ok        = true;
   c.lastBarTime = (datetime)SeriesInfoInteger(c.symbol, c.tf, SERIES_LASTBAR_DATE);
   return true;
}

// обновление контекста
bool TFContextUpdate(TFContext &c)
{
   if(!c.ok) return false;

   double a,b,d,e;
   if(!ReadLast(c.hADX,0,a)) a=c.adx;
   if(!ReadLast(c.hATR,0,b)) b=c.atr;
   if(!ReadLast(c.hSTD,0,d)) d=c.std;
   if(!ReadLast(c.hEMA,0,e)) e=c.ema;

   if(a==0 && b==0 && d==0) return false;

   c.adx=a; c.atr=b; c.std=d;
   c.slope=(e-c.ema)/MathMax(1e-8,MathAbs(c.ema));
   c.ema=e;
   return true;
}



#endif // __TFCONTEXT_MQH__
