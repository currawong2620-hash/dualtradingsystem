# **TECH_SPEC.md — Dual-Mode Forex System (v1.0 Core Specification)**

# TECH_SPEC.md  
## Dual-Mode Forex System — Technical Specification (v1.0 Core)

**Document Version:** 1.0  
**System Version:** Dual-Mode Forex System v1.0  
**Status:** Core Architecture Complete  
**License:** MIT  
**Author:** Dual-Mode Project Team  

---

# 1. Purpose & Scope

Dual-Mode Forex System — это модульная архитектура торгового эксперта  
для MetaTrader 5, который автоматически определяет **рыночный режим**  
и адаптирует торговую логику под состояние рынка.

Версия v1.0 включает:

- определение режима рынка (TREND / RANGE / TRANSITION),
- двухслойную модель прогнозирования (Forecast Engine),
- обновляемые индикаторные контексты (TFContext),
- внутренний симулятор сделок (Trade Simulator),
- учёт статистики (TradeStats),
- многострочную панель состояния,
- файловое логирование.

**Реальная торговля не включена.**  
В v1.1 появятся TrendEngine и RangeEngine.

---

# 2. High-Level Architecture

Dual-Mode Forex System разделён на независимые подсистемы:

```

Market Data  →  TFContext  →  Forecast Engine  →  Mode Analyzer
↓
Trade Manager
(Simulation)
↓
Trade Stats
↓
Info Panel & Logging

```

Система проектируется как **детерминированная**, модульная и горизонтально расширяемая.

---

# 3. Market Data Layer — TFContext

## 3.1 Назначение

TFContext отвечает за:

- инициализацию всех используемых индикаторов,
- безопасное обновление данных,
- хранение последнего состояния,
- вывод ошибок CopyBuffer,
- определение нового бара.

## 3.2 Индикаторы (в v1.0)

| Индикатор | MQL5 Handle | Использование |
|----------|-------------|--------------|
| ADX      | iADX        | сила тренда |
| ATR      | iATR        | волатильность, симулятор |
| StdDev   | iStdDev     | боковик / волатильность |
| MA       | iMA         | сглаживание bias |
| RSI      | iRSI        | вспомогательные фильтры |

---

# 4. Forecast Engine

Forecast Engine вычисляет сглаженную структуру рынка:

- bias — направленность (взвешенный дисбаланс индикаторов),
- μ — сглаженное среднее bias,
- σ — EMA отклонения,
- confidence — надёжность сигнала,
- локальная классификация TF (TREND UP / TREND DOWN / FLAT / UNCLEAR).

## 4.1 Расчёт bias

Для каждого TF:

```

metric_norm = Normalize(metric)
bias = Σ (weight_i × metric_norm_i)

```

Weights (v1.0):

| Metric | Weight |
|--------|--------|
| ADX    | 0.4 |
| ATR    | 0.3 |
| StdDev | 0.2 |
| Slope  | 0.1 |

## 4.2 Статистическая модель

```

μ      = EMA(bias, α=0.1)
σ      = EMA(|bias – μ|, α=0.1)
confidence = |bias| / (σ + ε)

```

## 4.3 Локальный режим TF

| Условие                         | Режим |
|--------------------------------|-------|
| |bias| < BiasFlatThreshold     | FLAT |
| confidence < ConfThreshold     | UNCLEAR |
| bias > 0                       | TREND UP |
| bias < 0                       | TREND DOWN |

---

# 5. Mode Analyzer (Market Regime Detector)

Mode Analyzer анализирует **старший TF** и управляет глобальным состоянием системы.

Состояния:

- `REGIME_TREND`
- `REGIME_RANGE`
- `REGIME_TRANSITION`

FSM-переходы:

```

if senior.confidence < LowConf:
→ REGIME_TRANSITION

if |senior.bias| > BiasTrend AND senior.confidence > ConfTrend:
→ REGIME_TREND

if |senior.bias| < BiasRange AND senior.confidence > ConfRange:
→ REGIME_RANGE

```

Hysteresis:  
Переход происходит только после **N подтверждённых баров** (по умолчанию 3).

---

# 6. Trade Layer

## 6.1 Overview

В v1.0 торговый слой работает в режиме:

```

Simulation Mode

```

Цели симулятора:

- испытание прогнозов,
- валидация FSM,
- отладка панелей и логики обновления контекстов,
- проверка корректности статистики.

Реальные сделки ещё не открываются.

---

## 6.2 Trade Types

Единая точка определения:

- ENUM_Regime
- ENUM_TradeMode
- TradeRecord
- SimTrade

---

## 6.3 TradeStats (учёт результатов)

Хранит:

- `equity`
- `wins`
- `losses`
- `totalProfit`
- `pf` (динамический)
- `winrate`
- `lastProfit`

Имеет методы:

```

AddTrade(double pl)
double GetPF()
double GetWinRate()

```

---

## 6.4 TradeSimulator

Симулятор использует:

- ATR текущего бара,
- режим рынка,
- случайность с фикс. μ и σ (по умолчанию μ = 1 pip, σ = 0.5 pip).

Модель v1.0:

```

if regime == TREND:
result = atr * 1.0
else:
result = -atr * 0.5

```

Это placeholder-модель, необходимая для тестирования связки модулей.

---

## 6.5 TradeManager

Роль:

- вызывается на каждом **новом баре** рабочего TF,
- обновляет симуляцию,
- передаёт результат в TradeStats,
- отвечает за инициализацию всех торговых модулей.

Интерфейс:

```

void Init(ENUM_TradeMode)
void OnNewBar(ENUM_Regime, ForecastResult work, ForecastResult senior, double atr)
double SimulateProfit(double atr)

```

---

# 7. Info Panel

Панель отображает:

- символ,
- режим (TREND/RANGE/TRANSITION),
- bias/μ/σ/conf для рабочего и старшего TF,
- локальные режимы TF,
- статистику торговли,
- equity, PF, WinRate.

Реализована через:

```

OBJ_RECTANGLE_LABEL
OBJ_LABEL

```

Панель многострочная, позиция регулируется входными параметрами EA.

---

# 8. Logging

## 8.1 Консоль

Уровни:

- LOG_DEBUG
- LOG_INFO
- LOG_WARN
- LOG_ERROR

## 8.2 Файл

Файл:

```

MQL5/Files/DualMode_Log.txt

```

Методы:

```

LogToFile(string)
LInfo, LDebug, LWarn, LErr

```

---

# 9. EA Main Loop (DualModeEA.mq5)

EA делает:

1. TFContextUpdate для рабочих TF  
2. Определение новых баров  
3. Обновление Forecast по новым барам  
4. ModeUpdate → глобальный режим  
5. TradeManager.OnNewBar (при новом баре рабочего TF)  
6. Обновление Panel  
7. Логирование  

Главный цикл **полностью событийный**, нет тяжёлых операций на каждом тике.

---

# 10. Inputs (входные параметры)

- `Inp_WorkTF` — рабочий TF (по умолчанию M5)  
- `Inp_SeniorTF` — старший TF (по умолчанию H1)  
- `Inp_PanelX/Y/W/H` — позиция панели  
- `Inp_ModeLogLevel` — уровень логирования  
- `Inp_TradeMode` — режим торговли (SIMULATION / REAL в будущем)

---

# 11. Requirements

## 11.1 MetaTrader

- MetaTrader 5 (build 3800+)  
- Windows 10/11  
- Хеджинг разрешён  

## 11.2 Минимум данных

Старший TF (обычно H1) должен иметь минимум 500 баров.

---

# 12. Versioning

Версия системы определяется тремя компонентами:

```

Major.Minor.Patch

```

Для v1.0:

- Major = 1 (стабильная архитектура)
- Minor = 0 (базовая функциональность)
- Patch = 0 (чистый baseline)

---

# 13. Planned Extensions (High-Level)

- TrendEngine (Donchian/EMA breakout)
- RangeEngine (BB mean reversion)
- Portfolio Mode
- News Filter
- ML Mode Analyzer
- Advanced Risk Engine
- Real Trading Layer

Полный план — в ROADMAP.md.

---

# 14. Summary

**Dual-Mode Forex System v1.0** — полноценная модульная архитектура,  
готовая к расширению в сторону реальной торговли, оптимизации и портфельного режима.

Версия v1.0:

- стабилизирует прогнозный слой,
- формирует режимы рынка,
- обеспечивает симуляцию сделок,
- предоставляет панель и логирование,
- создаёт фундамент для v1.1–v2.0.

Документ завершён.  
