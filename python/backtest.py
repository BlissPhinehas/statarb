import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

# ── Load signals CSV from OCaml engine ──
csv_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'signals.csv')
df = pd.read_csv(csv_path)

print("Signal Engine Output")
print("=" * 50)
print(df.to_string(index=False))
print(f"\nTotal rows  : {len(df)}")
print(f"BUY  signals: {(df['signal'] == 'BUY').sum()}")
print(f"SELL signals: {(df['signal'] == 'SELL').sum()}")
print(f"FLAT signals: {(df['signal'] == 'FLAT').sum()}")

# ── Simple backtest ──
# Rules:
#   BUY  signal -> go long  the spread (buy Y, sell X)
#   SELL signal -> go short the spread (sell Y, buy X)
#   FLAT        -> no position

position  = 0      # 1 = long, -1 = short, 0 = flat
pnl       = []
positions = []

for _, row in df.iterrows():
    sig = row['signal']
    if sig == 'BUY':
        position = 1
    elif sig == 'SELL':
        position = -1
    else:
        position = 0

    # P&L = position * negative z-score
    # (when long and z-score falls back to 0, we profit)
    daily_pnl = position * (-row['zscore']) * row['confidence']
    pnl.append(daily_pnl)
    positions.append(position)

df['position'] = positions
df['pnl']      = pnl
df['cum_pnl']  = df['pnl'].cumsum()

print(f"\nFinal cumulative P&L: {df['cum_pnl'].iloc[-1]:.4f}")

# ── Plot ──
fig, axes = plt.subplots(3, 1, figsize=(12, 9), sharex=True)
fig.suptitle('StatArb Signal Engine — GLD/SLV Pairs Trade', fontsize=14, fontweight='bold')

# Panel 1: Spread
axes[0].plot(df['index'], df['spread'], color='steelblue', linewidth=1.5)
axes[0].axhline(0, color='black', linewidth=0.8, linestyle='--')
axes[0].set_ylabel('Spread')
axes[0].set_title('OLS Spread (Y - alpha - beta*X)')
axes[0].grid(True, alpha=0.3)

# Panel 2: Z-Score with entry thresholds
axes[1].plot(df['index'], df['zscore'], color='darkorange', linewidth=1.5)
axes[1].axhline( 1.5, color='red',   linewidth=1, linestyle='--', label='+1.5 (SELL)')
axes[1].axhline(-1.5, color='green', linewidth=1, linestyle='--', label='-1.5 (BUY)')
axes[1].axhline( 0,   color='black', linewidth=0.8, linestyle='--')

# Mark BUY and SELL signals
buys  = df[df['signal'] == 'BUY']
sells = df[df['signal'] == 'SELL']
axes[1].scatter(buys['index'],  buys['zscore'],  color='green', zorder=5, label='BUY',  marker='^', s=80)
axes[1].scatter(sells['index'], sells['zscore'], color='red',   zorder=5, label='SELL', marker='v', s=80)
axes[1].set_ylabel('Z-Score')
axes[1].set_title('Z-Score with Entry Signals')
axes[1].legend(fontsize=8)
axes[1].grid(True, alpha=0.3)

# Panel 3: Cumulative P&L
axes[2].plot(df['index'], df['cum_pnl'], color='purple', linewidth=1.5)
axes[2].axhline(0, color='black', linewidth=0.8, linestyle='--')
axes[2].fill_between(df['index'], df['cum_pnl'], 0,
                     where=df['cum_pnl'] >= 0, alpha=0.2, color='green')
axes[2].fill_between(df['index'], df['cum_pnl'], 0,
                     where=df['cum_pnl'] < 0,  alpha=0.2, color='red')
axes[2].set_ylabel('Cumulative P&L')
axes[2].set_title('Backtest Cumulative P&L')
axes[2].set_xlabel('Bar Index')
axes[2].grid(True, alpha=0.3)

plt.tight_layout()

chart_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'signals_chart.png')
plt.savefig(chart_path, dpi=150, bbox_inches='tight')
print(f"\nChart saved to {chart_path}")
plt.show()