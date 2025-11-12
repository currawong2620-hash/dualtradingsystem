#ifndef __TRADE_RISK_MQH__
#define __TRADE_RISK_MQH__

#include "../Core/Config.mqh"
#include "Trade_Logger.mqh"

struct RiskModel
{
   double riskPerTradeTrend;
   double riskPerTradeRange;
   double dailyRiskLimit;
   double maxDD;
   double accountEquityStart;
   double cumulativeLoss;

   TradeLogger logger;  // не указатель, а экземпляр

   void Init(TradeLogger &log)
   {
      logger = log;  // копируем переданный логгер
      riskPerTradeTrend = 0.01;
      riskPerTradeRange = 0.005;
      dailyRiskLimit = 0.025;
      maxDD = 0.20;
      accountEquityStart = AccountInfoDouble(ACCOUNT_EQUITY);
      cumulativeLoss = 0.0;
   }

   double CalcLot(double riskFraction, double stopDistancePts)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskMoney = equity * riskFraction;
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double perPoint = tickVal / tickSize;
      double lots = riskMoney / (stopDistancePts * perPoint);
      lots = MathFloor(lots / lotStep) * lotStep;
      logger.Info(StringFormat("CalcLot: risk=%.2f%%, SL=%.1fpts, lot=%.3f", riskFraction*100.0, stopDistancePts, lots));
      return lots;
   }

   bool CheckDailyLoss(double profitToday)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double dd = (accountEquityStart - equity) / accountEquityStart;
      cumulativeLoss = dd;
      if(dd >= dailyRiskLimit)
      {
         logger.Error(StringFormat("Daily loss %.2f%% > limit %.2f%% — trading paused",
                        dd*100.0, dailyRiskLimit*100.0));
         return false;
      }
      return true;
   }
};

#endif // __TRADE_RISK_MQH__
