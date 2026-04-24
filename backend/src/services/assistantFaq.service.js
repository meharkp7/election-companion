// services/assistantFaq.service.js
// Specialized AI Assistant for Voter FAQs using Vertex AI

const { generateText } = require('../config/vertexai');

class AssistantFaqService {
  
  /**
   * Answer a voter's question using AI
   */
  async answerQuestion(question, userContext = {}) {
    const { state, isFirstTimeVoter, age } = userContext;
    
    const prompt = `
      You are the "Election Companion AI Assistant", a helpful, accurate, and non-partisan guide for Indian voters.
      Your goal is to help voters navigate the voting process, understand their rights, and solve problems at the polling booth.
      
      User Context:
      - State: ${state || 'India'}
      - First Time Voter: ${isFirstTimeVoter ? 'Yes' : 'No'}
      - User Age: ${age || 'Unknown'}
      
      User Question: "${question}"
      
      Instructions:
      1. Provide accurate information based on Election Commission of India (ECI) guidelines.
      2. If the user is facing an issue at the booth, give them immediate, actionable steps.
      3. Mention specific forms (like Form 6, Form 8) if applicable.
      4. If you are unsure, advise them to call the national voter helpline at 1950.
      5. Keep the tone encouraging, professional, and concise.
      6. Use bullet points for steps.
      
      Format the response as a JSON object:
      {
        "answer": "The main response text...",
        "suggestedActions": ["Action 1", "Action 2"],
        "helpfulLinks": [{"label": "ECI Website", "url": "https://voters.eci.gov.in"}],
        "emergencyContact": "1950"
      }
    `;

    try {
      const aiResponse = await generateText(prompt);
      
      // Clean up the response if AI adds markdown backticks
      const cleaned = aiResponse.replace(/```json|```/g, '').trim();
      try {
        return JSON.parse(cleaned);
      } catch (parseErr) {
        console.error('AI JSON Parse Error:', parseErr, 'Cleaned Content:', cleaned);
        return {
          answer: cleaned, // Fallback to raw text if it's not JSON
          suggestedActions: ["Call 1950"],
          emergencyContact: "1950"
        };
      }
    } catch (err) {
      console.error('AI FAQ Error:', err);
      return {
        answer: "I'm having trouble connecting to my knowledge base right now. For urgent help, please call the Voter Helpline at 1950 or visit voters.eci.gov.in.",
        suggestedActions: ["Call 1950", "Visit ECI Website"],
        emergencyContact: "1950"
      };
    }
  }

  /**
   * Get common FAQ categories
   */
  getQuickQuestions() {
    return [
      "What documents can I use instead of Voter ID?",
      "How do I find my booth?",
      "My name is not in the list, what do I do?",
      "Can I vote if I just moved cities?",
      "How does the EVM work?"
    ];
  }
}

module.exports = new AssistantFaqService();
