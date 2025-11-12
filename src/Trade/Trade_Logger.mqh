#ifndef __TRADE_LOGGER_MQH__
#define __TRADE_LOGGER_MQH__

#include "../Core/Logging.mqh"

enum ENUM_TradeLogLevel { TLOG_OFF=0, TLOG_BASIC=1, TLOG_VERBOSE=2 };

struct TradeLogger
{
   int level;

   void Init(int lvl=TLOG_BASIC) { level=lvl; }

   void Info(const string s)
   {
      if(level>=TLOG_BASIC) Print("[TRADE] ", s);
   }

   void Verbose(const string s)
   {
      if(level>=TLOG_VERBOSE) Print("[TRADE/DEBUG] ", s);
   }

   void Error(const string s)
   {
      Print("[TRADE/ERROR] ", s);
   }
};

#endif // __TRADE_LOGGER_MQH__
