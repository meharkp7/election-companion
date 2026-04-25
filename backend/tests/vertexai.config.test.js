/**
 * Unit tests for Vertex AI config module
 * Tests the mock fallback path (no real API calls).
 */

// Prevent actual VertexAI SDK from initialising
jest.mock('@google-cloud/vertexai', () => ({
  VertexAI: jest.fn().mockImplementation(() => ({
    preview: {
      getGenerativeModel: jest.fn().mockReturnValue({
        generateContent: jest.fn(),
        startChat: jest.fn(),
      }),
    },
  })),
}));

// Ensure env vars are NOT set so we exercise the mock path
delete process.env.GOOGLE_CLOUD_PROJECT_ID;

const { generateText, chatWithContext, isVertexAIConfigured } = require('../src/config/vertexai');

describe('Vertex AI config', () => {
  describe('isVertexAIConfigured', () => {
    it('returns false when GOOGLE_CLOUD_PROJECT_ID is not set', () => {
      expect(isVertexAIConfigured()).toBe(false);
    });
  });

  describe('generateText (mock path)', () => {
    it('returns a non-empty string for election-related prompt', async () => {
      const response = await generateText('Tell me about elections in India');
      expect(typeof response).toBe('string');
      expect(response.length).toBeGreaterThan(0);
    });

    it('returns a non-empty string for vote-related prompt', async () => {
      const response = await generateText('How do I vote?');
      expect(typeof response).toBe('string');
      expect(response.length).toBeGreaterThan(0);
    });

    it('returns a non-empty string for register-related prompt', async () => {
      const response = await generateText('How do I register to vote?');
      expect(typeof response).toBe('string');
      expect(response.length).toBeGreaterThan(0);
    });

    it('returns a generic response for unrecognised prompt', async () => {
      const response = await generateText('What is the weather today?');
      expect(typeof response).toBe('string');
      expect(response.length).toBeGreaterThan(0);
    });
  });

  describe('chatWithContext (mock path)', () => {
    it('returns text and updated context', async () => {
      const result = await chatWithContext('What is Form 6?', []);
      expect(result).toHaveProperty('text');
      expect(result).toHaveProperty('context');
      expect(typeof result.text).toBe('string');
      expect(Array.isArray(result.context)).toBe(true);
    });

    it('appends to existing context', async () => {
      const existingContext = [
        { role: 'user', parts: [{ text: 'Hello' }] },
        { role: 'model', parts: [{ text: 'Hi there!' }] },
      ];
      const result = await chatWithContext('Tell me more', existingContext);
      // Context should grow by 2 entries (user + model)
      expect(result.context.length).toBe(existingContext.length + 2);
    });
  });
});
