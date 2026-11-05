// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_tavily/otel_tavily.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(serviceName: 'otel_tavily-test');
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('search records depth + result count + credits', () async {
    await tracedTavily<String>(
      operation: 'search',
      invoke: () async => const TavilyCallResult(
        value: 'ok',
        result: TavilyResult(
          searchDepth: 'advanced',
          topic: 'news',
          maxResults: 10,
          resultCount: 10,
          includeAnswer: true,
          answerLength: 420,
          creditsUsed: 2,
          responseTimeMs: 850,
          timeRange: 'week',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('tavily search')!);
    expect(a['tavily.search.depth'], 'advanced');
    expect(a['tavily.credits.used'], 2);
    expect(a['tavily.time_range'], 'week');
  });

  test('insufficient_credits sets span error', () async {
    await tracedTavily<String>(
      operation: 'search',
      invoke: () async => const TavilyCallResult(
        value: 'ok',
        result:
            TavilyResult(errorCode: 'insufficient_credits', statusCode: 402),
      ),
    );
    expect(
      spans.findSpanByName('tavily search')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutTavilyInstrumentationAsync(() async {
      await tracedTavily<String>(
        operation: 'extract',
        invoke: () async => const TavilyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('tavily '), isEmpty);
  });
}
