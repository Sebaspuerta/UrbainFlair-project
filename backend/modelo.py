"""
Red neuronal (Keras / TensorFlow) que predice las unidades vendidas por
categoría en los meses siguientes.

La red aprende SOLA a partir de los datos de entrada y de salida:
  - Entrada : categoría + ventas de los 2 meses anteriores
  - Salida  : unidades vendidas del mes

No hay fórmulas escritas a mano: Keras entrena los pesos y el propio script
prueba varias arquitecturas (número de capas y neuronas), las VALIDA con los
últimos meses y se queda con la mejor.

Para usar datos reales basta reemplazar datos/ventas_mensuales.csv
(columnas: fecha YYYY-MM, categoria, unidades_vendidas).
"""
import json
import os
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras

BASE = Path(__file__).parent
RUTA_DATOS = BASE / "datos" / "ventas_mensuales.csv"
RUTA_MODELO = BASE / "modelo_guardado"

N_LAGS = 2            # meses anteriores que ve la red
MESES_VALIDACION = 2  # últimos meses de cada categoría reservados para validar
ARQUITECTURAS = [(4,), (8,), (16,), (8, 4), (16, 8), (32, 16)]
MAX_EPOCAS = 600
MESES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
         "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]


def etiqueta_mes(fecha: str) -> str:
    return MESES[int(fecha.split("-")[1]) - 1]


def siguiente_mes(fecha: str) -> str:
    anio, mes = map(int, fecha.split("-"))
    anio, mes = (anio + 1, 1) if mes == 12 else (anio, mes + 1)
    return f"{anio:04d}-{mes:02d}"


def cargar_datos() -> pd.DataFrame:
    df = pd.read_csv(RUTA_DATOS)
    return df.sort_values(["categoria", "fecha"]).reset_index(drop=True)


def _codificar(categoria: str, lags, categorias, mu, sd) -> np.ndarray:
    uno = [1.0 if c == categoria else 0.0 for c in categorias]
    return np.array(uno + [(v - mu) / sd for v in lags], dtype="float32")


def _muestras(df: pd.DataFrame, categorias, mu, sd):
    """Una muestra por (categoría, mes): entradas = categoría + N_LAGS meses
    previos; salida = ventas del mes. 'orden' es la posición del mes (0..)."""
    X, y, orden, cat = [], [], [], []
    for c in categorias:
        v = df[df.categoria == c].unidades_vendidas.tolist()
        for t in range(N_LAGS, len(v)):
            X.append(_codificar(c, v[t - N_LAGS:t], categorias, mu, sd))
            y.append((v[t] - mu) / sd)
            orden.append(t)
            cat.append(c)
    return np.array(X), np.array(y, dtype="float32"), np.array(orden), cat


def _construir(entradas: int, capas, lr=0.01) -> keras.Model:
    m = keras.Sequential([keras.layers.Input(shape=(entradas,))])
    for n in capas:
        m.add(keras.layers.Dense(n, activation="relu"))
    m.add(keras.layers.Dense(1))
    m.compile(optimizer=keras.optimizers.Adam(lr), loss="mse")
    return m


def entrenar(verbose: bool = True) -> dict:
    keras.utils.set_random_seed(42)
    df = cargar_datos()
    categorias = sorted(df.categoria.unique().tolist())
    mu = float(df.unidades_vendidas.mean())
    sd = float(df.unidades_vendidas.std()) or 1.0

    X, y, orden, cat = _muestras(df, categorias, mu, sd)
    # Validación "hacia adelante": se valida con los meses MÁS RECIENTES,
    # que es lo que la red tendrá que predecir en la vida real.
    max_orden = {c: max(o for o, k in zip(orden, cat) if k == c) for c in categorias}
    es_val = np.array([o > max_orden[k] - MESES_VALIDACION for o, k in zip(orden, cat)])
    Xtr, ytr, Xva, yva = X[~es_val], y[~es_val], X[es_val], y[es_val]
    if len(Xtr) < 4 or len(Xva) < 2:
        raise ValueError("Hay muy pocos meses de historia para entrenar y validar.")

    # Referencia: repetir el mes anterior (si la red no lo supera, no aporta).
    lag1 = Xva[:, len(categorias) + N_LAGS - 1]
    mae_base = float(np.mean(np.abs(lag1 - yva)) * sd)

    resultados = []
    for capas in ARQUITECTURAS:
        keras.utils.set_random_seed(42)
        m = _construir(X.shape[1], capas)
        cb = keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=60, restore_best_weights=True)
        h = m.fit(Xtr, ytr, validation_data=(Xva, yva), epochs=MAX_EPOCAS,
                  batch_size=4, verbose=0, callbacks=[cb])
        mae = float(np.mean(np.abs(m.predict(Xva, verbose=0)[:, 0] - yva)) * sd)
        epocas = int(np.argmin(h.history["val_loss"]) + 1)
        resultados.append({"capas": list(capas), "mae_validacion": round(mae, 2),
                           "epocas": epocas})
        if verbose:
            print(f"  capas={capas!s:9} MAE validación={mae:7.2f}  épocas={epocas}")

    mejor = min(resultados, key=lambda r: r["mae_validacion"])

    # Modelo final: misma arquitectura, entrenado con TODOS los meses.
    keras.utils.set_random_seed(42)
    final = _construir(X.shape[1], mejor["capas"])
    final.fit(X, y, epochs=max(mejor["epocas"], 50), batch_size=4, verbose=0)

    RUTA_MODELO.mkdir(exist_ok=True)
    final.save(RUTA_MODELO / "modelo.keras")
    info = {
        "categorias": categorias, "mu": mu, "sd": sd,
        "arquitectura_elegida": mejor["capas"],
        "mae_validacion": mejor["mae_validacion"],
        "mae_referencia_mes_anterior": round(mae_base, 2),
        "candidatas": resultados,
        "muestras_entrenamiento": int(len(Xtr)),
        "muestras_validacion": int(len(Xva)),
        "meses_historia": int(df.groupby("categoria").size().min()),
    }
    (RUTA_MODELO / "info.json").write_text(json.dumps(info, indent=2))
    if verbose:
        print(f"\nElegida: {mejor['capas']}  MAE={mejor['mae_validacion']}  "
              f"(referencia mes anterior: {mae_base:.2f})")
    return info


class Predictor:
    def __init__(self):
        if not (RUTA_MODELO / "modelo.keras").exists():
            print("No hay modelo guardado: entrenando...")
            entrenar()
        self.modelo = keras.models.load_model(RUTA_MODELO / "modelo.keras")
        self.info = json.loads((RUTA_MODELO / "info.json").read_text())
        self.df = cargar_datos()

    def reentrenar(self):
        entrenar()
        self.__init__()

    def historial(self, categoria: str):
        d = self.df[self.df.categoria == categoria]
        return [{"mes": etiqueta_mes(f), "unidades": int(u)}
                for f, u in zip(d.fecha, d.unidades_vendidas)]

    def predecir(self, categoria: str, meses: int):
        i = self.info
        if categoria not in i["categorias"]:
            raise KeyError(categoria)
        d = self.df[self.df.categoria == categoria]
        valores = d.unidades_vendidas.astype(float).tolist()
        fecha = d.fecha.iloc[-1]
        salida = []
        for _ in range(meses):  # cada predicción alimenta la siguiente
            x = _codificar(categoria, valores[-N_LAGS:], i["categorias"], i["mu"], i["sd"])
            p = float(self.modelo.predict(x[None, :], verbose=0)[0, 0]) * i["sd"] + i["mu"]
            p = max(0.0, p)
            valores.append(p)
            fecha = siguiente_mes(fecha)
            salida.append({"mes": etiqueta_mes(fecha), "unidades": int(round(p))})
        return salida


if __name__ == "__main__":
    print("Entrenando red neuronal y validando arquitecturas...")
    entrenar()