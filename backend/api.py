"""API que consume la app Flutter.  Ejecutar:  uvicorn api:app --port 8000"""
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from modelo import Predictor

app = FastAPI(title="Urban Flair - Predicción de ventas")
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])

predictor = Predictor()  # si no hay modelo guardado, se entrena solo


def _metricas():
    i = predictor.info
    return {
        "arquitectura": i["arquitectura_elegida"],
        "error_medio": i["mae_validacion"],
        "error_referencia": i["mae_referencia_mes_anterior"],
        "meses_historia": i["meses_historia"],
        "muestras_entrenamiento": i["muestras_entrenamiento"],
    }


@app.get("/salud")
def salud():
    return {"ok": True}


@app.get("/categorias")
def categorias():
    return predictor.info["categorias"]


@app.get("/predecir")
def predecir(categoria: str, meses: int = Query(3, ge=1, le=12)):
    try:
        pred = predictor.predecir(categoria, meses)
    except KeyError:
        raise HTTPException(404, f"Categoría desconocida: {categoria}")
    return {"categoria": categoria,
            "historial": predictor.historial(categoria),
            "prediccion": pred,
            "metricas": _metricas()}


@app.post("/reentrenar")
def reentrenar():
    predictor.reentrenar()
    return _metricas()