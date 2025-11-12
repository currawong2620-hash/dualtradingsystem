# Technical Specification — Dual-Mode Forex Trading System

## 1. Overview
Цель проекта — создать адаптивную торговую систему, способную автоматически
определять рыночное состояние (тренд / флэт) и активировать соответствующий
торговый движок. Система реализуется как эксперт-советник (EA) для MetaTrader 5
на языке MQL5 и рассчитана на тестирование и последующую работу на реальном рынке.

---

## 2. Market Regime Detection (Mode Analyzer)
- Используемые метрики:
  - ADX (сила тренда)
  - ATR (волатильность)
  - STD (стандартное отклонение)
  - EMA-slope (наклон средней)
  - Bollinger Band width (BBw)
- Алгоритм:
  - Расчёт агрегированного **bias** из нормализованных метрик.
  - Вычисление сглаженных μ и σ по bias.
  - Классификация:
    - `TREND_UP` / `TREND_DOWN`: ADX>Thr_H и |slope|>Thr_s.
    - `RANGE`: ADX<Thr_L и |bias|<thr_bias.
    - `TRANSITION`: промежуточная зона.
  - Гистерезис и требование N подтверждённых баров.
  - Confidence = |bias| / (σ + ε).

---

## 3. Trend Engine
- Таймфрейм: рабочий (например, M5)
- Сигналы входа:
  - Breakout Donchian(20) и ADX_H1>Thr_H
  - EMA(50)>EMA(200) для long (зеркально для short)
- Фильтры:
  - RSI < 70 (для long), > 30 (для short)
  - Исключение торговли вблизи крупных новостей
- Управление позицией:
  - SL = k_SL·ATR, TS = k_TS·ATR
  - Частичная фиксация прибыли
  - Reverse-martingale при серии прибыльных сделок
- Risk per trade ≤ 1 %

---

## 4. Range Engine
- Таймфрейм: рабочий (M5)
- Сигналы входа:
  - Покупка у нижней BB(20,2), RSI < 30, ADX_H1 < Thr_L
  - Продажа у верхней BB(20,2), RSI > 70
- Выход:
  - TP на средней линии, SL за границей канала
  - Прекращение входов при взлёте ADX > Thr_H
- Risk per trade ≤ 0.5 %

---

## 5. Mode Switch Mechanism
- FSM с тремя состояниями: `TREND`, `RANGE`, `TRANSITION`
- Переключение на новом баре старшего TF (H1)
- Требуется N_confirm баров устойчивости
- Volume policy:
  - TREND → Vtrend × f(conf)
  - RANGE → Vrange × f(conf)
  - TRANSITION → pause или 0.25×min(Vtrend,Vrange)

---

## 6. Risk Management
- Разделённые пулы: `TrendCapital`, `RangeCapital`
- Дневной риск-лимит: 2.5 %
- Общий DD-stop: 20 %
- Корреляционный фильтр по валютным парам
- Сессионный фильтр (для Range — Азия; для Trend — Лондон/Нью-Йорк)
- Auto kill-switch при аномалиях (disconnect, equity drop, copybuffer fail)

---

## 7. Architecture & Modules
| Модуль | Назначение |
|--------|-------------|
| **TFContext.mqh** | Индикаторы, копирование буферов, вычисление ATR/ADX/STD |
| **Forecast.mqh** | Bias, μ, σ, confidence, адаптивные пороги |
| **ModeAnalyzer.mqh** | FSM и классификация режима |
| **TrendEngine.mqh** | Входы/выходы в тренде |
| **RangeEngine.mqh** | Входы/выходы во флэте |
| **TradeManager.mqh** | Исполнение, лот контроль, MM и SL/TP |
| **Stats.mqh** | Метрики по режимам |
| **Panel_Main.mqh** | Отображение STATE, confidence, режима и PnL |

---

## 8. Backtesting & Evaluation
- Исторический период: 2015–2025
- Таймфреймы: H1→M5
- Метрики:
  - Profit Factor ≥ 1.35  
  - Sharpe ≥ 1.0  
  - Max DD ≤ 20 %  
  - PF_trend ≥ 1.5, PF_range ≥ 1.25
- Walk-Forward Optimization (кварталы)
- Отдельный отчёт по режимам

---

## 9. Implementation
- Платформа: MetaTrader 5  
- Язык: MQL5 (strict mode)  
- Минимальный набор индикаторов: ADX, ATR, EMA, BB, RSI, Donchian  
- Совместимость с EA-тестером и Live счётами (ECN)  
- Логирование в CSV + панель в реальном времени

---

## 10. Future Extensions
- ML-режим классификации (например, SVM/RandomForest)
- Мультисимвольная торговля
- Self-optimization по μ±σ-профилям
- Новостной модуль (встроенный фильтр по экономическому календарю)

---

© 2025 Dual-Mode Forex Project
