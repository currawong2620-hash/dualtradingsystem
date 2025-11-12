#ifndef __LOGGING_MQH__
#define __LOGGING_MQH__
#include <Trade/Trade.mqh>

enum LOGLEVEL { LOG_SILENT=0, LOG_INFO=1, LOG_DEBUG=2 };

// extern — определяется в DualModeEA.mq5
extern int gLogLevel;

void LogSetLevel(int lvl);
void LInfo (const string s);
void LDebug(const string s);
void LWarn (const string s);
void LErr  (const string s);

#endif // __LOGGING_MQH__
