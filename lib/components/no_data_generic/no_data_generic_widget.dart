import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'no_data_generic_model.dart';
export 'no_data_generic_model.dart';

class NoDataGenericWidget extends StatefulWidget {
  const NoDataGenericWidget({
    super.key,
    String? message,
  }) : this.message = message ?? 'No data found';

  final String message;

  @override
  State<NoDataGenericWidget> createState() => _NoDataGenericWidgetState();
}

class _NoDataGenericWidgetState extends State<NoDataGenericWidget> {
  late NoDataGenericModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NoDataGenericModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            'assets/images/No_data-pana.png',
            width: double.infinity,
            height: 110.0,
            fit: BoxFit.scaleDown,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
          child: Text(
            widget.message,
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                ),
          ),
        ),
      ],
    );
  }
}
