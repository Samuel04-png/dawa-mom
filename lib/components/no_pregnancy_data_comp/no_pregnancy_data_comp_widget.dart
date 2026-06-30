import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'no_pregnancy_data_comp_model.dart';
export 'no_pregnancy_data_comp_model.dart';

class NoPregnancyDataCompWidget extends StatefulWidget {
  const NoPregnancyDataCompWidget({
    super.key,
    this.parameter1,
  });

  final bool? parameter1;

  @override
  State<NoPregnancyDataCompWidget> createState() =>
      _NoPregnancyDataCompWidgetState();
}

class _NoPregnancyDataCompWidgetState extends State<NoPregnancyDataCompWidget> {
  late NoPregnancyDataCompModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NoPregnancyDataCompModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/images/Pregnancy_test-pana.png',
              width: double.infinity,
              height: 110.0,
              fit: BoxFit.scaleDown,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
            child: Text(
              'No pregnancy data',
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
