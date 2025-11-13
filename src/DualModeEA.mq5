//+------------------------------------------------------------------+
//| DualModeEA.mq5 — v1.2 Core + SimTrade + Panel                    |
//+------------------------------------------------------------------+
#property strict
#property version "1.2"

//--- Core includes
#include "Core/Config.mqh"
#include "Core/Logging.mqh"
#include "Core/TFContext.mqh"
#include "Core/Forecast.mqh"
#include "Core/ModeAnalyzer.mqh"

//--- UI
#include "Panels\\Panel_Main.mqh"

//--- Trade subsystem
#include "Trade\\Trade_Types.mqh"
#include "Trade\\Trade_Manager.mqh"

//==== глобальные структуры ========================================//
TFContext      gWorkCtx, gSeniorCtx;
ForecastState  gWorkFS,  gSeniorFS;
ForecastResult gWorkFR,  gSeniorFR;
ModeState      gMode;
PanelState     gPanel;
TradeManager   gTrade;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // 1) Логирование: файл + уровень
   LogFileOpen();
   LogSetLevel(Inp_ModeLogLevel);

   // 2) Инициализация индикаторных контекстов
   if(!TFContextInit(gWorkCtx,_Symbol,Inp_WorkTF))
   {
      LErr("TFContextInit failed for WorkTF");
      return(INIT_FAILED);
   }

   if(!TFContextInit(gSeniorCtx,_Symbol,Inp_SeniorTF))
   {
      LErr("TFContextInit failed for SeniorTF");
      return(INIT_FAILED);
   }

   // 3) Инициализация детектора режима
   ModeInit(gMode);

   // 4) Панель
   if(!PanelCreate(gPanel, Inp_PanelX, Inp_PanelY, Inp_PanelW, Inp_PanelH))
      LWarn("Panel not created");

   // 5) Торговый менеджер (пока только симуляция)
   gTrade.Init(TRADE_SIMULATION);

   LInfo("DualModeEA initialized");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PanelDestroy();
   LogFileClose();
   LInfo("DualModeEA deinitialized");
}

//+------------------------------------------------------------------+
//| expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1) --- Обновляем индикаторы на обоих ТФ ------------------------
   if(!TFContextUpdate(gWorkCtx) || !TFContextUpdate(gSeniorCtx))
      return;

   // 2) --- Определяем появление нового бара ------------------------
   datetime workLast   = (datetime)SeriesInfoInteger(_Symbol, Inp_WorkTF,   SERIES_LASTBAR_DATE);
   datetime seniorLast = (datetime)SeriesInfoInteger(_Symbol, Inp_SeniorTF, SERIES_LASTBAR_DATE);

   bool newW = (gWorkFR.barTime   != workLast);
   bool newS = (gSeniorFR.barTime != seniorLast);

   // 3) --- Обновляем прогнозы --------------------------------------
   if(newW)
      ForecastUpdate(gWorkCtx,   gWorkFS,   gWorkFR);

   if(newS)
      ForecastUpdate(gSeniorCtx, gSeniorFS, gSeniorFR);

   // 4) --- Обновляем режим рынка (по старшему ТФ) ------------------
   ENUM_Regime regime = ModeUpdate(gMode, gSeniorFR);

   // 5) --- Симуляция сделки на новом баре рабочего ТФ --------------
   if(newW)
   {
      gTrade.OnNewBar(regime,
                      gWorkFR,
                      gSeniorFR,
                      gWorkCtx.atr); // ATR рабочего ТФ
   }

   // 6) --- Перерисовываем панель ----------------------------------
   PanelUpdate(_Symbol,
               Inp_WorkTF,
               Inp_SeniorTF,
               gWorkFR,
               gSeniorFR,
               gTrade.stats,
               regime);
}
