#ifndef __TRADE_STATS_MQH__
#define __TRADE_STATS_MQH__

#include "Trade_Logger.mqh"

struct TradeStats
{
   int total;
   int wins;
   int losses;
   double grossProfit;
   double grossLoss;

   TradeLogger logger;

   void Init(TradeLogger &log)
   {
      logger = log;
      total = wins = losses = 0;
      grossProfit = grossLoss = 0.0;
   }

   void Record(double profit)
   {
      total++;
      if(profit > 0)
      {
         wins++;
         grossProfit += profit;
      }
      else
      {
         losses++;
         grossLoss += MathAbs(profit);
      }
      logger.Info(StringFormat("Trade closed: profit=%.2f | PF=%.2f", profit, PF()));
   }

   double PF() { return (grossLoss > 0 ? grossProfit / grossLoss : 0); }
   double WinRate() { return (total > 0 ? 100.0 * wins / total : 0); }
};

#endif // __TRADE_STATS_MQH__
