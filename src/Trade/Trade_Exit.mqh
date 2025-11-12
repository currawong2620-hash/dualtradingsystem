#ifndef __TRADE_EXIT_MQH__
#define __TRADE_EXIT_MQH__

#include "Trade_Logger.mqh"

struct TradeExit
{
   TradeLogger logger;

   void Init(TradeLogger &log)
   {
      logger = log;
   }

   bool ShouldExit(const double profit, const double atr)
   {
      bool exit = (profit > 3.0 * atr || profit < -1.5 * atr);
      if(exit)
         logger.Info(StringFormat("Exit signal triggered: profit=%.2f ATR=%.2f", profit, atr));
      return exit;
   }
};

#endif // __TRADE_EXIT_MQH__
