//+------------------------------------------------------------------+
//| DualModeEA.mq5 — v1.0 Core Skeleton (Test Panel Edition)        |
//+------------------------------------------------------------------+
#property strict
#property version "1.0"

#include "Config.mqh"
#include "Logging.mqh"
#include "TFContext.mqh"
#include "Forecast.mqh"
#include "ModeAnalyzer.mqh"
#include "..\\Panels\\Panel_Main.mqh"

//==== глобальные переменные ======================================//
int gLogLevel = LOG_INFO; // определение (extern в Logging.mqh)

// Реализация лог-функций
void LogSetLevel(int lvl){ gLogLevel=lvl; }
void LInfo (const string s){ if(gLogLevel>=LOG_INFO)  Print("[INFO] ",s); }
void LDebug(const string s){ if(gLogLevel>=LOG_DEBUG) Print("[DEBUG]",s); }
void LWarn (const string s){ Print("[WARN] ",s); }
void LErr  (const string s){ Print("[ERROR]",s); }

//==== глобальные структуры ========================================//
TFContext gWorkCtx,gSeniorCtx;
ForecastState gWorkFS,gSeniorFS;
ForecastResult gWorkFR,gSeniorFR;
ModeState gMode;
PanelState gPanel;

//------------------------------------------------------------------//
int OnInit()
{
   LogSetLevel(Inp_ModeLogLevel);
   if(!TFContextInit(gWorkCtx,_Symbol,Inp_WorkTF))   return INIT_FAILED;
   if(!TFContextInit(gSeniorCtx,_Symbol,Inp_SeniorTF)) return INIT_FAILED;
   ModeInit(gMode);
   if(!PanelCreate(gPanel, Inp_PanelX, Inp_PanelY, Inp_PanelW, Inp_PanelH))
    LWarn("Panel not created");

   LInfo("DualModeEA initialized");
   return(INIT_SUCCEEDED);
}

//------------------------------------------------------------------//
void OnDeinit(const int reason)
{
   PanelDestroy();
   LInfo("DualModeEA deinitialized");
}

//------------------------------------------------------------------//
void OnTick()
{
   // 1) Обновляем индикаторы
   if(!TFContextUpdate(gWorkCtx) || !TFContextUpdate(gSeniorCtx))
      return;

   // 2) Определяем, появился ли новый бар на каждом TF
   datetime workLast   = (datetime)SeriesInfoInteger(_Symbol, Inp_WorkTF,   SERIES_LASTBAR_DATE);
   datetime seniorLast = (datetime)SeriesInfoInteger(_Symbol, Inp_SeniorTF, SERIES_LASTBAR_DATE);

   bool newW = (gWorkFR.barTime   != workLast);
   bool newS = (gSeniorFR.barTime != seniorLast);

   // 3) Обновляем прогнозы только на новом баре соответствующего TF
   if(newW) ForecastUpdate(gWorkCtx,   gWorkFS,   gWorkFR);
   if(newS) ForecastUpdate(gSeniorCtx, gSeniorFS, gSeniorFR);

   // 4) Обновляем режим по старшему TF и перерисовываем панель
   ENUM_Regime regime = ModeUpdate(gMode, gSeniorFR);
   PanelUpdate(_Symbol, Inp_WorkTF, Inp_SeniorTF, gWorkFR, gSeniorFR, regime);
}
