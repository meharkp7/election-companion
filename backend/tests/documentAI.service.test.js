/**
 * Unit tests for DocumentAI service
 * Mocks Vertex AI so no real API calls are made.
 */

// Mock vertexai config before requiring the service
jest.mock('../src/config/vertexai', () => ({
  generateText: jest.fn(),
}));

jest.mock('../src/config/postgres', () => ({
  query: jest.fn(),
}));

const { generateText } = require('../src/config/vertexai');
const { query } = require('../src/config/postgres');
const documentAIService = require('../src/services/documentAI.service');

describe('DocumentAIService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── analyzeDocument ──────────────────────────────────────────────────────
  describe('analyzeDocument', () => {
    it('returns valid result when AI returns well-formed JSON', async () => {
      generateText.mockResolvedValue(JSON.stringify({
        isValid: true,
        confidenceScore: 0.95,
        issues: [],
        extractedData: { name: 'Rahul Sharma', aadhaarNumber: '1234 5678 9012' },
        suggestions: [],
      }));

      const result = await documentAIService.analyzeDocument(
        'https://example.com/doc.jpg',
        'aadhaar',
      );

      expect(result.success).toBe(true);
      expect(result.isValid).toBe(true);
      expect(result.confidenceScore).toBe(0.95);
      expect(result.issues).toHaveLength(0);
    });

    it('returns fallback result when AI throws', async () => {
      generateText.mockRejectedValue(new Error('Vertex AI unavailable'));

      const result = await documentAIService.analyzeDocument(
        'https://example.com/doc.jpg',
        'voter_id',
      );

      expect(result.success).toBe(false);
      expect(result.confidenceScore).toBe(0);
      expect(result.issues).toContain('ai_analysis_failed');
    });

    it('handles malformed JSON in AI response gracefully', async () => {
      generateText.mockResolvedValue('This document looks valid and complete.');

      const result = await documentAIService.analyzeDocument(
        'https://example.com/doc.jpg',
        'aadhaar',
      );

      // Falls back to text-based heuristic
      expect(result.success).toBe(true);
      expect(typeof result.isValid).toBe('boolean');
    });
  });

  // ── validateForBoothVisit ────────────────────────────────────────────────
  describe('validateForBoothVisit', () => {
    it('returns canProceed: false when no document uploaded', async () => {
      query.mockResolvedValue([]);

      const result = await documentAIService.validateForBoothVisit(
        'user-1',
        'aadhaar',
      );

      expect(result.canProceed).toBe(false);
      expect(result.action).toBe('upload_document');
    });

    it('returns canProceed: false when document has critical issues', async () => {
      query.mockResolvedValue([{
        is_valid: false,
        confidence_score: 0.3,
        issues: ['expired'],
        suggestions: ['Renew your Aadhaar'],
      }]);

      const result = await documentAIService.validateForBoothVisit(
        'user-1',
        'aadhaar',
      );

      expect(result.canProceed).toBe(false);
      expect(result.action).toBe('reupload_document');
    });

    it('returns canProceed: true with warning for low confidence', async () => {
      query.mockResolvedValue([{
        is_valid: true,
        confidence_score: 0.7,
        issues: [],
        suggestions: [],
      }]);

      const result = await documentAIService.validateForBoothVisit(
        'user-1',
        'voter_id',
      );

      expect(result.canProceed).toBe(true);
      expect(result.warning).toBeDefined();
    });

    it('returns canProceed: true for valid high-confidence document', async () => {
      query.mockResolvedValue([{
        is_valid: true,
        confidence_score: 0.95,
        issues: [],
        suggestions: [],
      }]);

      const result = await documentAIService.validateForBoothVisit(
        'user-1',
        'aadhaar',
      );

      expect(result.canProceed).toBe(true);
      expect(result.confidence).toBe(0.95);
    });
  });

  // ── validateAllDocuments ─────────────────────────────────────────────────
  describe('validateAllDocuments', () => {
    it('returns allValid: true when both documents pass', async () => {
      query.mockResolvedValue([{
        is_valid: true,
        confidence_score: 0.92,
        issues: [],
        suggestions: [],
      }]);

      const result = await documentAIService.validateAllDocuments('user-1');

      expect(result.allValid).toBe(true);
      expect(result.readyForBooth).toBe(true);
      expect(result.results).toHaveProperty('aadhaar');
      expect(result.results).toHaveProperty('voter_id');
    });

    it('returns allValid: false when one document fails', async () => {
      // First call (aadhaar) returns no rows → canProceed: false
      query
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{
          is_valid: true,
          confidence_score: 0.9,
          issues: [],
          suggestions: [],
        }]);

      const result = await documentAIService.validateAllDocuments('user-1');

      expect(result.allValid).toBe(false);
    });
  });
});
