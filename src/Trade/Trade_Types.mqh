#ifndef __TRADE_TYPES_MQH__
#define __TRADE_TYPES_MQH__

// Режим работы торговой подсистемы
enum ENUM_TradeMode
{
   TRADE_REAL = 0,        // Реальные ордера через CTrade
   TRADE_SIMULATION = 1   // Внутренний симулятор сделок
};

#endif
