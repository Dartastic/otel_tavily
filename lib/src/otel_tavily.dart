// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_tavily_suppression.dart';

const _tracerName = 'dartastic_otel_libs_tavily';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class TavilyResult {
  const TavilyResult({
    this.searchDepth,
    this.topic,
    this.queryLength,
    this.maxResults,
    this.resultCount,
    this.includeAnswer,
    this.answerLength,
    this.includeRawContent,
    this.includeImages,
    this.imageCount,
    this.includeDomains,
    this.excludeDomains,
    this.days,
    this.timeRange,
    this.responseTimeMs,
    this.creditsUsed,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `basic`, `advanced` (advanced costs more credits).
  final String? searchDepth;

  /// `general`, `news`, `finance`.
  final String? topic;

  final int? queryLength;

  final int? maxResults;
  final int? resultCount;

  /// Whether `answer` was requested + returned.
  final bool? includeAnswer;
  final int? answerLength;

  final bool? includeRawContent;

  final bool? includeImages;
  final int? imageCount;

  final List<String>? includeDomains;
  final List<String>? excludeDomains;

  /// `days` parameter on news/general topic.
  final int? days;

  /// `day`, `week`, `month`, `year`.
  final String? timeRange;

  final int? responseTimeMs;

  /// Tavily credits charged (1 credit per basic call, 2 per advanced).
  final int? creditsUsed;

  /// `bad_request`, `unauthorized`, `forbidden`, `not_found`,
  /// `rate_limit_exceeded`, `insufficient_credits`, `server_error`.
  final String? errorCode;
  final String? errorMessage;
  final int? statusCode;
}

class TavilyCallResult<T> {
  const TavilyCallResult({required this.value, this.result});
  final T value;
  final TavilyResult? result;
}

/// Wraps a Tavily API call in a CLIENT span. [operation] is one of
/// `search`, `extract`, `crawl`, `qna`, `getCompanyInfo`.
Future<T> tracedTavily<T>({
  required String operation,
  required Future<TavilyCallResult<T>> Function() invoke,
}) async {
  if (tavilyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'tavily',
    'rpc.method': operation,
    'tavily.operation': operation,
  };

  final span = _tracer().startSpan(
    'tavily $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.searchDepth != null) {
        extras.add(OTel.attributeString(
          'tavily.search.depth',
          res.searchDepth!,
        ));
      }
      if (res.topic != null) {
        extras.add(OTel.attributeString('tavily.topic', res.topic!));
      }
      if (res.queryLength != null) {
        extras.add(OTel.attributeInt(
          'tavily.query.length',
          res.queryLength!,
        ));
      }
      if (res.maxResults != null) {
        extras.add(OTel.attributeInt('tavily.max_results', res.maxResults!));
      }
      if (res.resultCount != null) {
        extras.add(OTel.attributeInt(
          'tavily.result.count',
          res.resultCount!,
        ));
      }
      if (res.includeAnswer != null) {
        extras.add(OTel.attributeBool(
          'tavily.include_answer',
          res.includeAnswer!,
        ));
      }
      if (res.answerLength != null) {
        extras.add(OTel.attributeInt(
          'tavily.answer.length',
          res.answerLength!,
        ));
      }
      if (res.includeRawContent != null) {
        extras.add(OTel.attributeBool(
          'tavily.include_raw_content',
          res.includeRawContent!,
        ));
      }
      if (res.includeImages != null) {
        extras.add(OTel.attributeBool(
          'tavily.include_images',
          res.includeImages!,
        ));
      }
      if (res.imageCount != null) {
        extras.add(OTel.attributeInt(
          'tavily.image.count',
          res.imageCount!,
        ));
      }
      if (res.includeDomains != null) {
        extras.add(OTel.attributeStringList(
          'tavily.include_domains',
          res.includeDomains!,
        ));
      }
      if (res.excludeDomains != null) {
        extras.add(OTel.attributeStringList(
          'tavily.exclude_domains',
          res.excludeDomains!,
        ));
      }
      if (res.days != null) {
        extras.add(OTel.attributeInt('tavily.days', res.days!));
      }
      if (res.timeRange != null) {
        extras.add(OTel.attributeString('tavily.time_range', res.timeRange!));
      }
      if (res.responseTimeMs != null) {
        extras.add(OTel.attributeInt(
          'tavily.response_time_ms',
          res.responseTimeMs!,
        ));
      }
      if (res.creditsUsed != null) {
        extras.add(OTel.attributeInt(
          'tavily.credits.used',
          res.creditsUsed!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'tavily.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'Tavily ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'tavily.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(SpanStatusCode.Error, 'Tavily HTTP ${res.statusCode}');
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
