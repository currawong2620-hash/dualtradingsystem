#ifndef __TRADE_STATS_MQH__
#define __TRADE_STATS_MQH__

struct TradeStats
{
   double equity;
   double grossProfit;
   double grossLoss;
   int wins;
   int losses;
   double lastProfit;

   void Init()
   {
      equity      = 0;
      grossProfit = 0;
      grossLoss   = 0;
      wins        = 0;
      losses      = 0;
      lastProfit  = 0;
   }

   void Record(double profit)
   {
      lastProfit = profit;
      equity += profit;

      if(profit > 0)
      {
         grossProfit += profit;
         wins++;
      }
      else if(profit < 0)
      {
         grossLoss += -profit; 
         losses++;
      }
   }

   double GetPF()
   {
      if(grossLoss == 0)
         return (grossProfit > 0 ? 999.0 : 1.0);
      return grossProfit / grossLoss;
   }

   double GetWinRate()
   {
      int total = wins + losses;
      if(total == 0) return 0.0;
      return 100.0 * wins / total;
   }
};

#endif
