const { VertexAI } = require('@google-cloud/vertexai');

// Initialize Vertex AI
const projectId = process.env.GOOGLE_CLOUD_PROJECT_ID;
const location = process.env.GOOGLE_CLOUD_LOCATION || 'us-central1';

// Check if Vertex AI is configured
const isVertexAIConfigured = () => {
  return projectId && projectId !== 'your-project-id-here';
};

let vertexAI = null;
let generativeModel = null;

if (isVertexAIConfigured()) {
  try {
    vertexAI = new VertexAI({ project: projectId, location: location });
    
    // Initialize Gemini model ( Google's generative AI model)
    generativeModel = vertexAI.preview.getGenerativeModel({
      model: 'gemini-pro',
    });
    
    console.log('✅ Vertex AI initialized');
  } catch (error) {
    console.warn('⚠️ Vertex AI initialization failed:', error.message);
  }
} else {
  console.log('ℹ️ Vertex AI not configured - AI features will use mock responses');
  console.log('Set GOOGLE_CLOUD_PROJECT_ID to enable Vertex AI');
}

// Generate text using Vertex AI Gemini
const generateText = async (prompt) => {
  if (!generativeModel) {
    return mockAIResponse(prompt);
  }

  try {
    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
    });
    
    const response = await result.response;
    return response.candidates[0].content.parts[0].text;
  } catch (error) {
    console.error('Vertex AI error:', error);
    return mockAIResponse(prompt);
  }
};

// Mock AI response for development
const mockAIResponse = (prompt) => {
  console.log('Using mock AI response for:', prompt.substring(0, 50) + '...');
  
  // Simple keyword-based responses for testing
  if (prompt.toLowerCase().includes('election')) {
    return 'Elections are the foundation of democracy. Make sure to check your voter registration status before election day!';
  }
  if (prompt.toLowerCase().includes('vote')) {
    return 'Voting is your right and responsibility. Find your polling station and required documents beforehand.';
  }
  if (prompt.toLowerCase().includes('register')) {
    return 'You can register to vote online or at your local election office. Ensure you have valid ID proof and address documents.';
  }
  
  return 'Thank you for your question about voting and elections. Please check official election commission resources for accurate information.';
};

// Chat with context (for conversational AI)
const chatWithContext = async (message, context = []) => {
  if (!generativeModel) {
    return mockAIResponse(message);
  }

  try {
    const chat = generativeModel.startChat({
      context: 'You are a helpful assistant for Indian election and voting queries.',
      history: context,
    });

    const result = await chat.sendMessage(message);
    const response = await result.response;
    return {
      text: response.candidates[0].content.parts[0].text,
      context: [...context, { role: 'user', parts: [{ text: message }] },
        { role: 'model', parts: [{ text: response.candidates[0].content.parts[0].text }] }],
    };
  } catch (error) {
    console.error('Vertex AI chat error:', error);
    return { text: mockAIResponse(message), context };
  }
};

module.exports = {
  vertexAI,
  generativeModel,
  generateText,
  chatWithContext,
  isVertexAIConfigured,
};
