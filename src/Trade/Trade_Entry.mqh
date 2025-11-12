#ifndef __TRADE_ENTRY_MQH__
#define __TRADE_ENTRY_MQH__

#include "../Core/Forecast.mqh"
#include "Trade_Logger.mqh"

struct TradeEntry
{
   TradeLogger logger;  // вместо указателя

   void Init(TradeLogger &log)
   {
      logger = log;     // копируем логгер по значению
   }

   bool ShouldEnterTrend(const ForecastResult &work, const ForecastResult &senior)
   {
      bool ok = (senior.confidence > 0.7 && work.confidence > 0.6 && MathAbs(work.bias) > 0.2);
      if(ok)
         logger.Info(StringFormat("Trend entry condition met (bias=%.2f, conf=%.2f)", work.bias, work.confidence));
      return ok;
   }

   bool ShouldEnterRange(const ForecastResult &work, const ForecastResult &senior)
   {
      bool ok = (senior.confidence < 0.6 && MathAbs(work.bias) < 0.2);
      if(ok)
         logger.Info("Range entry condition met");
      return ok;
   }
};

#endif // __TRADE_ENTRY_MQH__
