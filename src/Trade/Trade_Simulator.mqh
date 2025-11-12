#ifndef __TRADE_SIMULATOR_MQH__
#define __TRADE_SIMULATOR_MQH__

#include "Trade_Logger.mqh"

struct TradeSimulator
{
   double meanSlippage;
   double stdSlippage;
   TradeLogger logger;

   void Init(TradeLogger &log)
   {
      logger = log;
      meanSlippage = 1.0;   // 1 pip
      stdSlippage  = 0.5;
   }

   double ApplySlippage(double price)
   {
      double slip = meanSlippage + stdSlippage * (MathRand() / 32767.0 - 0.5);
      logger.Verbose(StringFormat("Simulated slippage = %.2f pips", slip));
      return price + slip * _Point;
   }
};

#endif // __TRADE_SIMULATOR_MQH__
