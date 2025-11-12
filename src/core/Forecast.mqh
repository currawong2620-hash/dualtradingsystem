#ifndef __FORECAST_MQH__
#define __FORECAST_MQH__
#include "Config.mqh"
#include "TFContext.mqh"

struct ForecastResult
{
   datetime barTime;
   double   bias;
   double   mu;
   double   sigma;
   double   confidence;
};

struct ForecastState
{
   bool   inited;
   double mu;
   double sigma;
};
// безопасная реализация гиперболического тангенса
double TanH(const double x)
{
   if(x>20.0)  return 1.0;
   if(x<-20.0) return -1.0;
   double e2 = MathExp(2.0*x);
   return (e2-1.0)/(e2+1.0);
}

double EmaUpdate(const double prev, const double x, const double alpha)
{ return (1.0-alpha)*prev + alpha*x; }

double NormADX(const double adx)
{
   double n = _Clamp01((adx - ADX_THR_LOW)/(ADX_THR_HIGH-ADX_THR_LOW + 1e-8));
   return 2.0*n - 1.0;
}
double NormATR(const double atr, const double std)
{
   if(std<=1e-12) return 0.0;
   double r = atr/std;
   return TanH(r-1.0);
}
double NormSTD(const double std, const double atr)
{
   if(atr<=1e-12) return 0.0;
   double r = std/atr;
   double n = 1.0 - TanH(MathMax(0.0, r-1.0));
   return 2.0*(n-0.5);
}
double NormSlope(const double slope){ return TanH(5.0*slope); }

bool ForecastUpdate(const TFContext &ctx, ForecastState &st, ForecastResult &out)
{
   if(!ctx.ok) return false;
   double nADX   = NormADX(ctx.adx);
   double nATR   = NormATR(ctx.atr, ctx.std);
   double nSTD   = NormSTD(ctx.std, ctx.atr);
   double nSLOPE = NormSlope(ctx.slope);

   double bias = Inp_Weight_ADX*nADX + Inp_Weight_ATR*nATR + Inp_Weight_STD*nSTD + Inp_Weight_Slope*nSLOPE;
   bias = MathMax(-1.0, MathMin(1.0, bias));

   const double alpha_mu = 0.10;
   const double alpha_sg = 0.10;
   if(!st.inited){ st.inited=true; st.mu=bias; st.sigma=0.05; }
   else{
      st.mu    = EmaUpdate(st.mu, bias, alpha_mu);
      st.sigma = EmaUpdate(st.sigma, MathAbs(bias - st.mu), alpha_sg);
   }

   const double eps=1e-6;
   out.barTime   = (datetime)SeriesInfoInteger(ctx.symbol, ctx.tf, SERIES_LASTBAR_DATE);
   out.bias      = bias;
   out.mu        = st.mu;
   out.sigma     = st.sigma;
   out.confidence= MathMin(1.5, MathAbs(bias)/(st.sigma+eps));
   return true;
}

#endif // __FORECAST_MQH__
