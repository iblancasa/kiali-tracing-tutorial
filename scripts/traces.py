#!/usr/bin/env python3
"""Summarise the latest traces of one service, straight from the Jaeger API.

    scripts/traces.py                              # traces that start at the ingress gateway
    scripts/traces.py orders.demo                  # traces where orders.demo appears
    scripts/traces.py --show 1                     # also print the span tree of the biggest trace

One line per trace: how many spans, how many services, how long. It is the
quickest way to see whether the spans of one request ended up in one trace
or in many. Needs only Python 3 and the Jaeger port (localhost:16686).
"""
import argparse
import datetime
import json
import urllib.parse
import urllib.request


def attributes(items):
    return {a['key']: next(iter(a['value'].values()), '') for a in items or []}


def fetch(base, service, minutes, limit):
    # Stop 10 seconds ago: the spans of the newest traces are still arriving.
    now = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(seconds=10)
    stamp = lambda t: t.strftime('%Y-%m-%dT%H:%M:%SZ')
    query = urllib.parse.urlencode({
        'query.service_name': service,
        'query.start_time_min': stamp(now - datetime.timedelta(minutes=minutes)),
        'query.start_time_max': stamp(now),
        'query.search_depth': limit,
    })
    with urllib.request.urlopen(f'{base}/api/v3/traces?{query}', timeout=20) as response:
        result = json.load(response).get('result', {})
    traces = {}
    for resource_spans in result.get('resourceSpans', []):
        name = attributes(resource_spans.get('resource', {}).get('attributes')).get('service.name', '?')
        for scope_spans in resource_spans.get('scopeSpans', []):
            for span in scope_spans.get('spans', []):
                span['service'] = name
                span['start'] = int(span['startTimeUnixNano'])
                span['end'] = int(span['endTimeUnixNano'])
                span['tags'] = attributes(span.get('attributes'))
                traces.setdefault(span['traceId'], []).append(span)
    return sorted(traces.values(), key=lambda spans: -min(s['start'] for s in spans))


def is_error(span):
    return span.get('status', {}).get('code') in (2, 'STATUS_CODE_ERROR') or span['tags'].get('error') in (True, 'true')


def tree(spans):
    ids = {s['spanId'] for s in spans}
    children = {}
    for span in sorted(spans, key=lambda s: s['start']):
        parent = span.get('parentSpanId') if span.get('parentSpanId') in ids else None
        children.setdefault(parent, []).append(span)

    def walk(parent, depth):
        for span in children.get(parent, []):
            ms = (span['end'] - span['start']) / 1e6
            mark = '  ERROR' if is_error(span) else ''
            print(f"  {'  ' * depth}{span['service']:<{max(1, 36 - 2 * depth)}} {ms:7.1f} ms  {span['name'][:60]}{mark}")
            walk(span['spanId'], depth + 1)

    walk(None, 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('service', nargs='?', default='istio-ingressgateway.istio-system')
    parser.add_argument('--jaeger', default='http://localhost:16686')
    parser.add_argument('--minutes', type=int, default=2, help='look back this many minutes (default 2)')
    parser.add_argument('--limit', type=int, default=200, help='ask Jaeger for at most this many traces')
    parser.add_argument('--lines', type=int, default=8, help='print this many traces (default 8)')
    parser.add_argument('--show', type=int, default=0, metavar='N', help='print the span tree of the N biggest traces')
    args = parser.parse_args()

    traces = fetch(args.jaeger, args.service, args.minutes, args.limit)
    if not traces:
        print(f'no traces of {args.service} in the last {args.minutes} min')
        return
    print(f'{"TRACE":<10} {"SPANS":>5} {"SERVICES":>8} {"ERRORS":>6} {"DURATION":>10}  ROOT')
    for spans in traces[:args.lines]:
        ids = {s['spanId'] for s in spans}
        root = next((s for s in sorted(spans, key=lambda s: s['start']) if s.get('parentSpanId') not in ids), spans[0])
        ms = (max(s['end'] for s in spans) - min(s['start'] for s in spans)) / 1e6
        print(f"{spans[0]['traceId'][:8]:<10} {len(spans):>5} {len({s['service'] for s in spans}):>8} "
              f"{sum(is_error(s) for s in spans):>6} {ms:>7.0f} ms  {root['service']}: {root['name'][:50]}")
    counts = sorted(len(spans) for spans in traces)
    print(f'\n{len(traces)} traces of {args.service} in the last {args.minutes} min. '
          f'Spans per trace: min {counts[0]}, median {counts[len(counts) // 2]}, max {counts[-1]}.')
    for spans in sorted(traces, key=len, reverse=True)[:args.show]:
        print(f"\ntrace {spans[0]['traceId']}")
        tree(spans)


if __name__ == '__main__':
    main()
