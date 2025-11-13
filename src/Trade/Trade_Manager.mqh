#ifndef __TRADE_MANAGER_MQH__
#define __TRADE_MANAGER_MQH__

#include "Trade_Types.mqh"
#include "Trade_Logger.mqh"
#include "Trade_Stats.mqh"
#include "Trade_Simulator.mqh"
#include "../Core/Forecast.mqh"
#include "../Core/ModeAnalyzer.mqh"

//-----------------------------------------------------------
// TradeManager — управляет симуляцией сделок
//-----------------------------------------------------------
struct SimTrade
{
   bool active;
   double openPrice;
   datetime openTime;
   ENUM_Regime regime;

   void Reset()
   {
      active    = false;
      openPrice = 0;
      openTime  = 0;
      regime    = REGIME_TRANSITION;  // безопасное состояние
   }
};

//-----------------------------------------------------------
struct TradeManager
{
   ENUM_TradeMode mode;

   TradeLogger logger;
   TradeStats stats;
   TradeSimulator simulator;
   SimTrade trade;

   //-------------------------------------------------------
   void Init(ENUM_TradeMode m = TRADE_SIMULATION)
   {
      mode = m;

      logger.Init();
      stats.Init();
      simulator.Init(logger);

      trade.Reset();

      LInfo("TradeManager initialized. Mode=" + EnumToString(mode));
   }

   //-------------------------------------------------------
   // Обработка нового бара на рабочем ТФ
   //-------------------------------------------------------
   void OnNewBar(ENUM_Regime regime,
                 const ForecastResult &work,
                 const ForecastResult &senior,
                 double atr)
   {
      if(mode != TRADE_SIMULATION)
         return;

      // TRANSITION = без сделок
      if(regime == REGIME_TRANSITION)
         return;

      //---------------------------------------------------
      // 1. Закрываем предыдущую виртуальную сделку
      //---------------------------------------------------
      if(trade.active)
      {
         double profit = SimulateProfit(atr);

         stats.Record(profit);

         LInfo("SimTrade closed: " + DoubleToString(profit,2));

         trade.Reset();
      }

      //---------------------------------------------------
      // 2. Открываем новую виртуальную сделку
      //---------------------------------------------------
      trade.active    = true;
      trade.openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      trade.openTime  = TimeCurrent();
      trade.regime    = regime;

      LInfo("SimTrade opened. Regime=" + EnumToString(regime));
   }

   //-------------------------------------------------------
   // Простая модель симулированного профита
   //-------------------------------------------------------
   double SimulateProfit(double atr)
   {
      // RANDOM прибыль от -1.5 ATR до +2.0 ATR
      double r = -1.5 + 3.5 * (MathRand() / 32767.0);
      return atr * r;
   }
};

#endif
