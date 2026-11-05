// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_tavily/otel_tavily.dart';

/// Traces Tavily calls with OpenTelemetry.
///
/// `otel_tavily` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Tavily call in
/// [tracedTavily]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'tavily-example');

  // Wraps a Tavily API call in a CLIENT span.
  final tavilyId = await tracedTavily<String>(
    operation: 'create',
    invoke: () async {
      // Make the Tavily call here, then report what it returned.
      const id = 'tavily_8f3a2c';
      return const TavilyCallResult(
          value: id,
          result: TavilyResult(
              searchDepth: 'basic',
              topic: 'general',
              queryLength: 1,
              maxResults: 1,
              resultCount: 3,
              includeAnswer: true,
              answerLength: 1,
              includeRawContent: true,
              includeImages: true,
              imageCount: 3,
              includeDomains: ['example'],
              excludeDomains: ['example'],
              days: 1,
              timeRange: 'day',
              responseTimeMs: 120,
              creditsUsed: 1,
              errorCode: 'bad_request',
              errorMessage: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedTavily create returned $tavilyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutTavilyInstrumentationAsync.
  await runWithoutTavilyInstrumentationAsync(
    () => tracedTavily<String>(
      operation: 'create',
      invoke: () async {
        const id = 'tavily_8f3a2c';
        return const TavilyCallResult(
            value: id,
            result: TavilyResult(
                searchDepth: 'basic',
                topic: 'general',
                queryLength: 1,
                maxResults: 1,
                resultCount: 3,
                includeAnswer: true,
                answerLength: 1,
                includeRawContent: true,
                includeImages: true,
                imageCount: 3,
                includeDomains: ['example'],
                excludeDomains: ['example'],
                days: 1,
                timeRange: 'day',
                responseTimeMs: 120,
                creditsUsed: 1,
                errorCode: 'bad_request',
                errorMessage: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
