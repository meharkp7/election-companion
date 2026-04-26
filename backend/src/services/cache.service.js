/**
 * In-memory TTL cache service
 *
 * Provides a lightweight application-level cache with:
 *  - Per-entry TTL (time-to-live)
 *  - Prefix-based invalidation
 *  - getOrSet helper for cache-aside pattern
 *  - Hit/miss metrics
 *  - Periodic sweep to free expired entries
 *
 * Designed to be swappable with Redis — replace the internal Map
 * with an ioredis client and the public API stays identical.
 */

/** @type {Map<string, { value: any, expiresAt: number }>} */
const store = new Map();

/** Metrics counters */
const metrics = { hits: 0, misses: 0, sets: 0, deletes: 0 };

// ── Sweep expired entries every 5 minutes ──────────────────────────────────
const SWEEP_INTERVAL_MS = 5 * 60 * 1000;
const sweepTimer = setInterval(() => {
  const now = Date.now();
  let swept = 0;
  for (const [key, entry] of store.entries()) {
    if (entry.expiresAt <= now) {
      store.delete(key);
      swept++;
    }
  }
  if (swept > 0) {
    console.log(`[cache] swept ${swept} expired entries`);
  }
}, SWEEP_INTERVAL_MS);

// Don't block process exit
if (sweepTimer.unref) sweepTimer.unref();

// ── Core operations ─────────────────────────────────────────────────────────

/**
 * Store a value with a TTL.
 *
 * @param {string} key
 * @param {*}      value
 * @param {number} [ttlSeconds=300]  Defaults to 5 minutes
 */
function set(key, value, ttlSeconds = 300) {
  store.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
  metrics.sets++;
}

/**
 * Retrieve a cached value.
 * Returns `undefined` if the key is missing or expired.
 *
 * @param {string} key
 * @returns {*}
 */
function get(key) {
  const entry = store.get(key);
  if (!entry) {
    metrics.misses++;
    return undefined;
  }
  if (entry.expiresAt <= Date.now()) {
    store.delete(key);
    metrics.misses++;
    return undefined;
  }
  metrics.hits++;
  return entry.value;
}

/**
 * Delete a single cache entry.
 *
 * @param {string} key
 */
function del(key) {
  if (store.delete(key)) metrics.deletes++;
}

/**
 * Delete all entries whose key starts with `prefix`.
 * Useful for invalidating a whole category (e.g. "stats:").
 *
 * @param {string} prefix
 * @returns {number} Number of entries removed
 */
function invalidatePrefix(prefix) {
  let count = 0;
  for (const key of store.keys()) {
    if (key.startsWith(prefix)) {
      store.delete(key);
      count++;
    }
  }
  metrics.deletes += count;
  return count;
}

/**
 * Cache-aside helper.
 * Returns the cached value if present; otherwise calls `fetchFn`,
 * stores the result, and returns it.
 *
 * @template T
 * @param {string}          key
 * @param {() => Promise<T>} fetchFn
 * @param {number}          [ttlSeconds=300]
 * @returns {Promise<T>}
 */
async function getOrSet(key, fetchFn, ttlSeconds = 300) {
  const cached = get(key);
  if (cached !== undefined) return cached;

  const value = await fetchFn();
  set(key, value, ttlSeconds);
  return value;
}

/**
 * Return cache health statistics.
 *
 * @returns {{ size: number, hits: number, misses: number, hitRate: string, sets: number, deletes: number }}
 */
function healthStats() {
  const total = metrics.hits + metrics.misses;
  return {
    size: store.size,
    hits: metrics.hits,
    misses: metrics.misses,
    hitRate: total ? `${((metrics.hits / total) * 100).toFixed(1)}%` : 'n/a',
    sets: metrics.sets,
    deletes: metrics.deletes,
  };
}

/** Flush all entries (useful in tests). */
function flush() {
  store.clear();
  metrics.hits = 0;
  metrics.misses = 0;
  metrics.sets = 0;
  metrics.deletes = 0;
}

module.exports = { get, set, del, invalidatePrefix, getOrSet, healthStats, flush };
