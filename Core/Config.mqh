#ifndef __CONFIG_MQH__
#define __CONFIG_MQH__

//====================[ ВХОДНЫЕ ПАРАМЕТРЫ ]========================//
input ENUM_TIMEFRAMES Inp_WorkTF   = PERIOD_M5;
input ENUM_TIMEFRAMES Inp_SeniorTF = PERIOD_H1;

input double Inp_Weight_ADX   = 0.40;
input double Inp_Weight_ATR   = 0.30;
input double Inp_Weight_STD   = 0.20;
input double Inp_Weight_Slope = 0.10;

input int    Inp_ConfirmBars  = 3;
input int    Inp_ModeLogLevel = 1;

//---- позиция панели
input int    Inp_PanelX = 10;
input int    Inp_PanelY = 30;
input int    Inp_PanelW = 420;
input int    Inp_PanelH = 160;

//====================[ КОНСТАНТЫ ]================================//
#define ADX_THR_LOW   17.0
#define ADX_THR_HIGH  25.0
#define SLOPE_THR     0.10

#define _Clamp01(x)   (MathMax(0.0, MathMin(1.0, (x))))
#define _Sign(x)      ((x)>0?1:((x)<0?-1:0))

#endif // __CONFIG_MQH__
