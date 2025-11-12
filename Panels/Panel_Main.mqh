#ifndef __PANEL_MAIN_MQH__
#define __PANEL_MAIN_MQH__
#include "../Core/ModeAnalyzer.mqh"
#include "../Core/Forecast.mqh"

#define PANEL_BG   "DM_TestPanel_BG"
#define PANEL_LINE "DM_TestPanel_LINE_"

struct PanelState
{
   bool created;
   int x,y,w,h;
   string font;
   int fontsize;
   int lines;
};

// простая функция повторения строки
string StringRepeat(const string s,const int count)
{
   string out=""; for(int i=0;i<count;i++) out+=s; return out;
}

// цвет по режиму
color RegimeTextColor(const ENUM_Regime r)
{
   if(r==REGIME_TREND) return clrLime;
   if(r==REGIME_RANGE) return clrAqua;
   return clrYellow;
}

// определение локального режима по bias/conf
string LocalRegime(const ForecastResult &f)
{
   if(MathAbs(f.bias)<0.15) return "FLAT";
   if(f.confidence<0.6)     return "UNCLEAR";
   return (f.bias>0?"TREND ↑":"TREND ↓");
}

// создание панели
bool PanelCreate(PanelState &p, const int x, const int y, const int w, const int h)
{
   p.x=x; p.y=y; p.w=w; p.h=h; p.font="Consolas"; p.fontsize=10; p.lines=0;
   ObjectDelete(0,PANEL_BG);
   for(int i=0;i<20;i++) ObjectDelete(0,PANEL_LINE+(string)i);

   // фон
   if(!ObjectCreate(0,PANEL_BG,OBJ_RECTANGLE_LABEL,0,0,0))
      return false;
   ObjectSetInteger(0,PANEL_BG,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_XDISTANCE,p.x);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_YDISTANCE,p.y);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_XSIZE,p.w);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_YSIZE,p.h);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_BGCOLOR,clrBlack);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_COLOR,clrBlack);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_BACK,false);
   ObjectSetInteger(0,PANEL_BG,OBJPROP_HIDDEN,true);
   p.created=true;
   return true;
}

// удаление
void PanelDestroy()
{
   ObjectDelete(0,PANEL_BG);
   for(int i=0;i<20;i++) ObjectDelete(0,PANEL_LINE+(string)i);
}

// вспомогательное форматирование
string FormatLine(const string k,const string v,const int pad=12)
{
   string key=k; if(StringLen(key)<pad) key+=StringRepeat(" ",pad-StringLen(key));
   return key+": "+v;
}

// вывод одной строки
void DrawLine(int index,const string text,int x,int y,color clr,const string font,int fontsize)
{
   string name=PANEL_LINE+(string)index;
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x+8);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y+8+index*(fontsize+2));
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString (0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetString (0,name,OBJPROP_TEXT,text);
}

// обновление панели
void PanelUpdate(const string symbol,const ENUM_TIMEFRAMES workTF,const ENUM_TIMEFRAMES seniorTF,
                 const ForecastResult &work,const ForecastResult &senior,const ENUM_Regime regime)
{
   if(ObjectFind(0, PANEL_BG) < 0) return;
   color txtColor = RegimeTextColor(regime);

   string lines[];
   ArrayResize(lines, 20);
   int n = 0;

   lines[n++] = "Dual-Mode EA — Test Panel";
   lines[n++] = FormatLine("Symbol", symbol);
   lines[n++] = FormatLine("Global Regime",
                 (regime==REGIME_TREND?"TREND":(regime==REGIME_RANGE?"RANGE":"TRANSITION")));
   lines[n++] = "";
   lines[n++] = "Work TF (" + EnumToString(workTF) + ")";
   lines[n++] = StringFormat("  bias=%+.3f  μ=%+.3f  σ=%.3f  conf=%.2f",
                             work.bias, work.mu, work.sigma, work.confidence);
   lines[n++] = "  → " + LocalRegime(work);
   lines[n++] = "";
   lines[n++] = "Senior TF (" + EnumToString(seniorTF) + ")";
   lines[n++] = StringFormat("  bias=%+.3f  μ=%+.3f  σ=%.3f  conf=%.2f",
                             senior.bias, senior.mu, senior.sigma, senior.confidence);
   lines[n++] = "  → " + LocalRegime(senior);

   for(int i=0;i<n;i++)
      DrawLine(i, lines[i], Inp_PanelX, Inp_PanelY, txtColor, "Consolas", 10);
}

#endif // __PANEL_MAIN_MQH__
