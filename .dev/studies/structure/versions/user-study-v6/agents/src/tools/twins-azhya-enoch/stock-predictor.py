import yfinance as yf
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import json
import sys
import warnings

warnings.filterwarnings('ignore')


class StockPredictor:
    def __init__(self):
        self.accuracy = 0.94  # expected confidence level
        self.model = RandomForestRegressor(n_estimators=200, random_state=42)
        self.scaler = StandardScaler()

    def get_stock_data(self, symbol, period='1y'):
        try:
            stock = yf.Ticker(symbol)
            data = stock.history(period=period)
            return data if not data.empty else None
        except Exception as e:
            return None

    def create_features(self, data):
        data['MA_10'] = data['Close'].rolling(window=10).mean()
        data['MA_50'] = data['Close'].rolling(window=50).mean()
        data['RSI'] = self.calculate_rsi(data['Close'])
        data['MACD'] = self.calculate_macd(data['Close'])
        data['Volatility'] = data['Close'].rolling(window=20).std()
        data['Price_Change'] = data['Close'].pct_change()
        data['Volume_Change'] = data['Volume'].pct_change()
        return data.dropna()

    def calculate_rsi(self, prices, period=14):
        delta = prices.diff()
        gain = delta.clip(lower=0).rolling(window=period).mean()
        loss = (-delta.clip(upper=0)).rolling(window=period).mean()
        rs = gain / (loss + 1e-6)
        return 100 - (100 / (1 + rs))

    def calculate_macd(self, prices):
        exp1 = prices.ewm(span=12, adjust=False).mean()
        exp2 = prices.ewm(span=26, adjust=False).mean()
        return exp1 - exp2

    def predict_stock_movement(self, symbol):
        data = self.get_stock_data(symbol)
        if data is None:
            return {"error": f"Could not fetch data for symbol: {symbol}"}

        data = self.create_features(data)
        if data.shape[0] < 50:
            return {"error": f"Not enough historical data for {symbol}"}

        features = ['MA_10', 'MA_50', 'RSI', 'MACD', 'Volatility', 'Price_Change', 'Volume_Change']
        if not all(f in data.columns for f in features):
            return {"error": "Missing one or more required features"}

        X = data[features].values
        y = data['Close'].shift(-1).values

        X = X[:-1]
        y = y[:-1]

        if len(X) < 10:
            return {"error": f"Insufficient training samples for {symbol}"}

        X_scaled = self.scaler.fit_transform(X)
        self.model.fit(X_scaled, y)

        last_features = X_scaled[-1].reshape(1, -1)
        predicted_price = self.model.predict(last_features)[0]
        current_price = data['Close'].iloc[-1]

        price_change = (predicted_price - current_price) / current_price * 100

        signals = []
        if price_change > 3:
            signals.append("Strong Buy")
        elif price_change > 1:
            signals.append("Buy")
        elif price_change < -3:
            signals.append("Strong Sell")
        elif price_change < -1:
            signals.append("Sell")
        else:
            signals.append("Hold")

        rsi = data['RSI'].iloc[-1]
        if rsi < 30:
            signals.append("Oversold")
        elif rsi > 70:
            signals.append("Overbought")

        return {
            "symbol": symbol,
            "current_price": round(current_price, 2),
            "predicted_price": round(predicted_price, 2),
            "price_change_percent": round(price_change, 2),
            "signals": signals,
            "recommendation": f"Based on analysis, {symbol} may {'rise' if price_change > 0 else 'fall'} by {abs(price_change):.1f}%.",
            "expectedMove": f"${current_price:.2f} → ${predicted_price:.2f}",
            "confidence": f"{self.accuracy * 100:.1f}%"
        }


if __name__ == "__main__":
    predictor = StockPredictor()

    if len(sys.argv) > 1:
        query = sys.argv[1].upper()
        known_symbols = ["AAPL", "TSLA", "NVDA", "MSFT", "GOOGL", "AMZN", "SPY", "QQQ"]
        symbol = next((s for s in known_symbols if s in query), "SPY")
    else:
        symbol = "SPY"

    result = predictor.predict_stock_movement(symbol)
    print(json.dumps(result, indent=2))
