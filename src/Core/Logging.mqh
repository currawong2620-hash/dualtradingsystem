#ifndef __LOGGING_MQH__
#define __LOGGING_MQH__

//-------------------------------------------
// Уровни логирования
//-------------------------------------------
#define LOG_ERROR 0
#define LOG_WARN  1
#define LOG_INFO  2
#define LOG_DEBUG 3

int gLogLevel = LOG_INFO;      // ← глобальный текущий уровень

//-------------------------------------------
// Файловый лог
//-------------------------------------------
int gFileHandle = INVALID_HANDLE;

void LogFileOpen()
{
   if(gFileHandle != INVALID_HANDLE)
      return;

   string filename = "DualModeEA.log";
   gFileHandle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_ANSI);

   if(gFileHandle == INVALID_HANDLE)
      Print("[ERROR] Failed to open log file: ", filename);
   else
      Print("[INFO] Log file created: ", filename);
}

void LogFileClose()
{
   if(gFileHandle != INVALID_HANDLE)
      FileClose(gFileHandle);

   gFileHandle = INVALID_HANDLE;
}

void LogFileWrite(const string prefix,const string msg)
{
   if(gFileHandle == INVALID_HANDLE)
      return;

   string s =
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      + " " + prefix + " " + msg + "\n";

   FileWriteString(gFileHandle, s);
   FileFlush(gFileHandle);
}

//-------------------------------------------
// Основные лог-функции
//-------------------------------------------
void LogSetLevel(int lvl)
{
   gLogLevel = lvl;
   LogFileWrite("[INFO]", "Log level set to " + IntegerToString(lvl));
}

void LInfo(const string s)
{
   if(gLogLevel >= LOG_INFO)
      Print("[INFO] ", s);

   LogFileWrite("[INFO]", s);
}

void LDebug(const string s)
{
   if(gLogLevel >= LOG_DEBUG)
      Print("[DEBUG] ", s);

   LogFileWrite("[DEBUG]", s);
}

void LWarn(const string s)
{
   Print("[WARN] ", s);
   LogFileWrite("[WARN]", s);
}

void LErr(const string s)
{
   Print("[ERROR] ", s);
   LogFileWrite("[ERROR]", s);
}

#endif
