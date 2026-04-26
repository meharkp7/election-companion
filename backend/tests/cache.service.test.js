/**
 * Unit tests for the in-memory cache service.
 * No external dependencies — pure logic tests.
 */

const cache = require('../src/services/cache.service');

beforeEach(() => cache.flush());

// ── set / get ────────────────────────────────────────────────────────────────
describe('cache.set / cache.get', () => {
  it('stores and retrieves a value', () => {
    cache.set('key1', { foo: 'bar' }, 60);
    expect(cache.get('key1')).toEqual({ foo: 'bar' });
  });

  it('returns undefined for a missing key', () => {
    expect(cache.get('nonexistent')).toBeUndefined();
  });

  it('returns undefined after TTL expires', () => {
    // Set with 0-second TTL (already expired)
    cache.set('expired', 'value', 0);
    expect(cache.get('expired')).toBeUndefined();
  });

  it('overwrites an existing key', () => {
    cache.set('k', 'first', 60);
    cache.set('k', 'second', 60);
    expect(cache.get('k')).toBe('second');
  });

  it('stores falsy values correctly', () => {
    cache.set('zero', 0, 60);
    cache.set('empty', '', 60);
    cache.set('false', false, 60);
    expect(cache.get('zero')).toBe(0);
    expect(cache.get('empty')).toBe('');
    expect(cache.get('false')).toBe(false);
  });
});

// ── del ──────────────────────────────────────────────────────────────────────
describe('cache.del', () => {
  it('removes a key', () => {
    cache.set('toDelete', 'value', 60);
    cache.del('toDelete');
    expect(cache.get('toDelete')).toBeUndefined();
  });

  it('does not throw when deleting a non-existent key', () => {
    expect(() => cache.del('ghost')).not.toThrow();
  });
});

// ── invalidatePrefix ─────────────────────────────────────────────────────────
describe('cache.invalidatePrefix', () => {
  it('removes all keys with the given prefix', () => {
    cache.set('stats:app', 1, 60);
    cache.set('stats:turnout', 2, 60);
    cache.set('other:key', 3, 60);

    const removed = cache.invalidatePrefix('stats:');
    expect(removed).toBe(2);
    expect(cache.get('stats:app')).toBeUndefined();
    expect(cache.get('stats:turnout')).toBeUndefined();
    expect(cache.get('other:key')).toBe(3);
  });

  it('returns 0 when no keys match', () => {
    cache.set('foo', 1, 60);
    expect(cache.invalidatePrefix('bar:')).toBe(0);
  });
});

// ── getOrSet ─────────────────────────────────────────────────────────────────
describe('cache.getOrSet', () => {
  it('calls fetchFn on cache miss and stores result', async () => {
    const fetchFn = jest.fn().mockResolvedValue({ data: 42 });
    const result = await cache.getOrSet('miss-key', fetchFn, 60);

    expect(result).toEqual({ data: 42 });
    expect(fetchFn).toHaveBeenCalledTimes(1);
  });

  it('returns cached value without calling fetchFn on hit', async () => {
    cache.set('hit-key', { data: 99 }, 60);
    const fetchFn = jest.fn();

    const result = await cache.getOrSet('hit-key', fetchFn, 60);
    expect(result).toEqual({ data: 99 });
    expect(fetchFn).not.toHaveBeenCalled();
  });

  it('propagates fetchFn errors', async () => {
    const fetchFn = jest.fn().mockRejectedValue(new Error('DB down'));
    await expect(cache.getOrSet('err-key', fetchFn, 60)).rejects.toThrow('DB down');
  });
});

// ── healthStats ──────────────────────────────────────────────────────────────
describe('cache.healthStats', () => {
  it('returns expected shape', () => {
    const stats = cache.healthStats();
    expect(stats).toHaveProperty('size');
    expect(stats).toHaveProperty('hits');
    expect(stats).toHaveProperty('misses');
    expect(stats).toHaveProperty('hitRate');
    expect(stats).toHaveProperty('sets');
    expect(stats).toHaveProperty('deletes');
  });

  it('tracks hits and misses correctly', () => {
    cache.set('tracked', 'v', 60);
    cache.get('tracked');   // hit
    cache.get('missing');   // miss

    const stats = cache.healthStats();
    expect(stats.hits).toBeGreaterThanOrEqual(1);
    expect(stats.misses).toBeGreaterThanOrEqual(1);
  });

  it('reports n/a hitRate when no requests made', () => {
    expect(cache.healthStats().hitRate).toBe('n/a');
  });
});
