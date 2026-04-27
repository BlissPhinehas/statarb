# StatArb Signal Engine

A statistical arbitrage trading system that identifies trading signals by analyzing the spread between correlated assets (GLD/SLV). Built with OCaml for the core signal processing engine and Python for data fetching.

## Overview

StatArb uses **Welford's online algorithm** to compute rolling mean and variance of spreads, then applies **Z-score normalization** to detect trading opportunities:
- **BUY signal**: When the z-score falls below a negative threshold (spread is undervalued)
- **SELL signal**: When the z-score rises above a positive threshold (spread is overvalued)
- **FLAT**: No significant trading opportunity

## Project Structure

```
StatArb/
├── bin/
│   ├── dune              # OCaml build config for executable
│   └── main.ml           # Main entry point (reads prices, generates signals)
├── lib/
│   ├── dune              # OCaml build config for library
│   ├── stats.ml          # Statistical functions (Welford, z-score, correlation)
│   └── signals.ml        # Signal generation logic
├── test/
│   ├── dune              # Test configuration
│   └── test_statarb.ml   # Unit tests (OUnit2)
├── python/
│   ├── fetch_data.py     # Download GLD/SLV historical data from Yahoo Finance
│   └── backtest.py       # Backtesting framework (placeholder)
├── data/
│   ├── prices.csv        # Downloaded market data (generated)
│   └── signals.csv       # Generated trading signals (generated)
└── dune-project          # Project configuration
```

## Prerequisites

### System Requirements
- **OCaml** 4.08+
- **Dune** 3.0+ (OCaml build system)
- **Python** 3.10+

### Installation

#### Ubuntu/Debian
```bash
# Install OCaml tools
sudo apt install -y ocaml-dune libounit-ocaml-dev ocaml-findlib

# Install Python dependencies
pip install pandas yfinance
```

#### macOS (Homebrew)
```bash
brew install ocaml dune
pip install pandas yfinance
```

## Quick Start

### 1. Download Market Data
```bash
cd /path/to/StatArb
python3 python/fetch_data.py
```

This downloads 1 year of historical data for GLD (Gold ETF) and SLV (Silver ETF) from Yahoo Finance and saves to `data/prices.csv`.

### 2. Build the Project
```bash
dune build
```

### 3. Generate Signals
```bash
dune exec bin/main.exe
```

**Example Output:**
```
StatArb Signal Engine
======================
Assets  : GLD / SLV (real data)
Bars    : 250
Window  : 30 bars
Entry Z : 1.5

Index  Spread       Z-Score  Signal Confidence
--------------------------------------------------
42     -0.3255      -1.2541  BUY    0.1641
51      0.2144       1.0823  SELL   0.0549
...
```

### 4. Run Tests
```bash
dune test
```

All 12 unit tests validate:
- Welford mean/variance calculations
- Z-score normalization
- Signal generation logic

## Core Algorithms

### Welford's Online Algorithm
Computes rolling mean and variance without storing all values:
```
n += 1
delta = x - mean
mean += delta / n
delta2 = x - mean
m2 += delta * delta2
variance = m2 / (n - 1)
```

### Spread Calculation
Uses **Ordinary Least Squares (OLS)** regression to model:
```
SLV = alpha + beta * GLD + residual
spread = residual
```

The residual (spread) captures the relative mispricing between the two assets.

### Z-Score Signal Generation
For each bar, computes rolling z-score over a sliding window:
```
z = (spread[i] - mean) / std
```

Signals trigger when z crosses thresholds:
- **z < -entry_z**: BUY (mean reversion expected)
- **z > +entry_z**: SELL (mean reversion expected)

## Configuration

Edit `bin/main.ml` to adjust parameters:
```ocaml
let window  = 30  in    (* Rolling window size in bars *)
let entry_z = 1.5 in   (* Z-score threshold for signals *)
```

Also modify `python/fetch_data.py` to change date range:
```python
yf.download("GLD", start="2023-01-01", end="2024-01-01", ...)
```

<img width="1784" height="1328" alt="image" src="https://github.com/user-attachments/assets/7638997b-8e99-48e3-9fc4-f7f1b58d05a7" />

## Limitations & Future Work

- **No transaction costs**: Real trading includes fees/slippage
- **No execution simulation**: Signals are generated, not traded
- **Static parameters**: Window/threshold are hardcoded
- **Single pair**: Currently only GLD/SLV, extend to other correlated assets
- **No position management**: Missing stop-loss/take-profit logic

## References

- **Welford's Algorithm**: [Numerically stable variance computation](https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Welford's_online_algorithm)
- **Statistical Arbitrage**: Pairs trading via mean reversion
- **yfinance**: [Yahoo Finance data fetcher](https://github.com/ranaroussi/yfinance)

## License

MIT

## Author

Bliss

---

**Last Updated**: April 26, 2026  
**Status**: Active Development
