import yfinance as yf
import pandas as pd
import os

# ── Download GLD and SLV historical data ──
print("Downloading GLD and SLV data from Yahoo Finance...")

data = yf.download(["GLD", "SLV"], start="2023-01-01", end="2024-01-01",
                   auto_adjust=True, progress=False)

# Extract closing prices for each ticker
gld_close = data["Close"]["GLD"].dropna()
slv_close = data["Close"]["SLV"].dropna()

# Align on common dates
df = pd.DataFrame({"GLD": gld_close, "SLV": slv_close}).dropna()

print(f"Downloaded {len(df)} trading days")
print(f"Date range: {df.index[0].date()} to {df.index[-1].date()}")
print(f"\nGLD price range: ${df['GLD'].min():.2f} - ${df['GLD'].max():.2f}")
print(f"SLV price range: ${df['SLV'].min():.2f} - ${df['SLV'].max():.2f}")

# ── Save to CSV for OCaml engine ──
out_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'prices.csv')
df.to_csv(out_path)
print(f"\nPrices saved to {out_path}")