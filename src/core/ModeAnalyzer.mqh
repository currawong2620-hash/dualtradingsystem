#ifndef __MODEANALYZER_MQH__
#define __MODEANALYZER_MQH__
#include "Config.mqh"
#include "Logging.mqh"
#include "Forecast.mqh"

enum ENUM_Regime { REGIME_RANGE=0, REGIME_TREND=1, REGIME_TRANSITION=2 };

struct ModeState
{
   ENUM_Regime regime;
   int confirmCnt;
   int desired;
};

void ModeInit(ModeState &m){ m.regime=REGIME_TRANSITION; m.confirmCnt=0; m.desired=0; }

ENUM_Regime ModeDecide(const ForecastResult &senior)
{
   bool isTrend = (MathAbs(senior.bias)>0.25 && senior.confidence>0.8);
   return isTrend ? REGIME_TREND : REGIME_RANGE;
}

ENUM_Regime ModeUpdate(ModeState &m, const ForecastResult &senior)
{
   ENUM_Regime want = ModeDecide(senior);
   if(m.regime==REGIME_TRANSITION)
   {
      m.confirmCnt++;
      if(m.confirmCnt>=Inp_ConfirmBars){ m.regime=want; m.confirmCnt=0; }
      return m.regime;
   }
   if(m.regime!=want){ m.regime=REGIME_TRANSITION; m.confirmCnt=0; return REGIME_TRANSITION; }
   return m.regime;
}

#endif // __MODEANALYZER_MQH__
