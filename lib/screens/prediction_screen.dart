import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../data/prediccion_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/encabezado_azul.dart';

/// Predicción de ventas: la red neuronal vive en el backend Python
/// (backend/modelo.py) y esta pantalla solo pide y muestra el resultado.
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  static const _opcionesMeses = ['1', '2', '3', '4', '5', '6'];

  final _api = PrediccionApi();
  final _formKey = GlobalKey<FormState>();

  List<String>? _categorias;
  String? _categoria;
  String _meses = '3';

  bool _cargando = false;
  String? _error;
  ResultadoPrediccion? _resultado;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final c = await _api.categorias();
      if (mounted) setState(() => _categorias = c);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'No se pudo conectar con el servidor de Python (${PrediccionApi.baseUrl}).\n'
            'Inícialo con:  uvicorn api:app --port 8000');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _predecir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _api.predecir(_categoria!, int.parse(_meses));
      if (mounted) setState(() => _resultado = r);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo obtener la predicción. '
            'Verifica que el servidor de Python siga corriendo.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _grafica(ResultadoPrediccion r) {
    // La línea de predicción parte del último mes real para que se una.
    final desdeUltimo = [r.historial.last, ...r.prediccion];
    return Container(
      height: 280,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 6)),
        ],
      ),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Ventas de ${r.categoria}'),
        legend: const Legend(
            isVisible: true,
            position: LegendPosition.bottom,
            overflowMode: LegendItemOverflowMode.wrap),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
        primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Unidades')),
        series: <CartesianSeries<PuntoMes, String>>[
          LineSeries<PuntoMes, String>(
            name: 'Real',
            color: AppColors.azulEncabezado,
            dataSource: r.historial,
            xValueMapper: (p, _) => p.mes,
            yValueMapper: (p, _) => p.unidades,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
          LineSeries<PuntoMes, String>(
            name: 'Predicción',
            color: AppColors.rojoCerrar,
            dashArray: const <double>[6, 4],
            dataSource: desdeUltimo,
            xValueMapper: (p, _) => p.mes,
            yValueMapper: (p, _) => p.unidades,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _tablaPrediccion(ResultadoPrediccion r) {
    final total = r.prediccion.fold(0.0, (s, p) => s + p.unidades);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (final p in r.prediccion)
              _FilaTabla(etiqueta: p.mes, valor: '${p.unidades.round()} unidades'),
            _FilaTabla(
                etiqueta: 'Total',
                valor: '${total.round()} unidades',
                destacada: true),
          ],
        ),
      ),
    );
  }

  Widget _nota(ResultadoPrediccion r) {
    final mejora = r.errorMedio < r.errorReferencia;
    return Text(
      'Red neuronal con capas ocultas ${r.arquitectura.join(' → ')}, elegida '
      'automáticamente entre varias arquitecturas. Error medio en validación: '
      '± ${r.errorMedio.toStringAsFixed(1)} unidades '
      '(repetir el mes anterior: ± ${r.errorReferencia.toStringAsFixed(1)}). '
      '${mejora ? '' : 'La red aún no supera esa referencia. '}'
      'Historia usada: ${r.mesesHistoria} meses; con más meses reales la '
      'predicción mejora.',
      style: AppTextStyles.archivo(
          color: AppColors.textoGris, fontWeight: FontWeight.w700, fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoAzul(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    Text('Predicción De Ventas',
                        style: AppTextStyles.tituloPantalla),
                    const SizedBox(height: 6),
                    Text(
                        'Una red neuronal estima cuántas unidades vas a vender en los próximos meses.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.normal12),
                    const SizedBox(height: 18),
                    if (_categorias != null)
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ListaFormulario(
                                      etiqueta: 'Categoría',
                                      items: _categorias!,
                                      onChanged: (v) => _categoria = v),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ListaFormulario(
                                      etiqueta: 'Meses a predecir',
                                      items: _opcionesMeses,
                                      onChanged: (v) => _meses = v ?? _meses),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _predecir,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.guardar,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('Predecir',
                                    style: AppTextStyles.negrita),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_cargando)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.archivo(
                                    color: AppColors.rojoCerrar,
                                    fontWeight: FontWeight.w700)),
                            if (_categorias == null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _cargarCategorias,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (r != null) ...[
                      const SizedBox(height: 24),
                      _grafica(r),
                      const SizedBox(height: 20),
                      _tablaPrediccion(r),
                      const SizedBox(height: 14),
                      _nota(r),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaTabla extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacada;

  const _FilaTabla(
      {required this.etiqueta, required this.valor, this.destacada = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 112,
            color: destacada ? AppColors.azulEncabezado : AppColors.azulInventario,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(etiqueta,
                style: AppTextStyles.blancoNegrita14),
          ),
          Expanded(
            child: Container(
              color: AppColors.celdaInventario,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(valor,
                  style: AppTextStyles.archivo(
                      color: Colors.black87,
                      fontWeight: destacada ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}