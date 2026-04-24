// services/documentAI.service.js
// AI-Powered Document Verification using Vertex AI Gemini

const { generateText } = require('../config/vertexai');

class DocumentAIService {
  
  /**
   * Analyze uploaded document for validity and issues
   * @param {string} fileUrl - URL of uploaded document
   * @param {string} documentType - 'aadhaar', 'voter_id', 'passport', 'dl'
   * @returns {Promise<Object>} Validation result with AI analysis
   */
  async analyzeDocument(fileUrl, documentType) {
    try {
      // Build prompt for document analysis
      const prompt = this._buildDocumentPrompt(fileUrl, documentType);
      
      // Get AI analysis from Vertex AI Gemini
      const aiResponse = await generateText(prompt, {
        temperature: 0.1, // Low temperature for consistent results
        maxOutputTokens: 1024,
      });
      
      // Parse AI response
      const analysis = this._parseAIResponse(aiResponse, documentType);
      
      return {
        success: true,
        isValid: analysis.isValid,
        confidenceScore: analysis.confidenceScore,
        issues: analysis.issues,
        extractedData: analysis.extractedData,
        suggestions: analysis.suggestions,
        rawAnalysis: aiResponse,
      };
    } catch (error) {
      console.error('Document AI analysis failed:', error);
      
      // Return fallback result with helpful suggestions
      return {
        success: false,
        isValid: null,
        confidenceScore: 0,
        issues: ['ai_analysis_failed'],
        suggestions: ['Please try uploading again with better lighting'],
        error: error.message,
      };
    }
  }
  
  /**
   * Validate document before user travels to booth
   * Checks if document is valid, not expired, and complete
   */
  async validateForBoothVisit(userId, documentType) {
    // Get user's latest document validation
    const { query } = require('../config/postgres');
    
    const validations = await query(
      `SELECT * FROM document_validations 
       WHERE user_id = $1 AND document_type = $2 
       ORDER BY created_at DESC LIMIT 1`,
      [userId, documentType]
    );
    
    if (validations.length === 0) {
      return {
        canProceed: false,
        reason: 'No document uploaded',
        action: 'upload_document',
      };
    }
    
    const validation = validations[0];
    
    // Check for critical issues
    const criticalIssues = ['expired', 'invalid_format', 'unreadable', 'fake_detected'];
    const hasCriticalIssues = validation.issues?.some(issue => 
      criticalIssues.includes(issue)
    );
    
    if (hasCriticalIssues) {
      return {
        canProceed: false,
        reason: 'Document has critical issues',
        issues: validation.issues,
        action: 'reupload_document',
        suggestions: validation.suggestions,
      };
    }
    
    if (!validation.is_valid) {
      return {
        canProceed: false,
        reason: 'Document validation failed',
        issues: validation.issues,
        action: 'review_document',
      };
    }
    
    if (validation.confidence_score < 0.8) {
      return {
        canProceed: true,
        warning: 'Low confidence in document validation',
        suggestion: 'Carry original documents as backup',
      };
    }
    
    return {
      canProceed: true,
      confidence: validation.confidence_score,
      message: 'Document validated successfully',
    };
  }
  
  /**
   * Batch validate all user documents
   */
  async validateAllDocuments(userId) {
    const documentTypes = ['aadhaar', 'voter_id'];
    const results = {};
    
    for (const docType of documentTypes) {
      results[docType] = await this.validateForBoothVisit(userId, docType);
    }
    
    const allValid = Object.values(results).every(r => r.canProceed);
    
    return {
      allValid,
      results,
      readyForBooth: allValid,
    };
  }
  
  /**
   * Build AI prompt for document analysis
   */
  _buildDocumentPrompt(fileUrl, documentType) {
    const documentRequirements = {
      aadhaar: {
        name: 'Aadhaar Card',
        requiredFields: ['Aadhaar Number', 'Name', 'Date of Birth', 'Address', 'Photo'],
        validityChecks: ['Not expired', 'Complete visible', 'Photo clear', 'QR scannable'],
      },
      voter_id: {
        name: 'Voter ID (EPIC)',
        requiredFields: ['EPIC Number', 'Name', 'Age', 'Photo', 'Constituency'],
        validityChecks: ['Not expired', 'Complete visible', 'Photo clear'],
      },
      passport: {
        name: 'Passport',
        requiredFields: ['Passport Number', 'Name', 'Date of Birth', 'Photo', 'Expiry Date'],
        validityChecks: ['Not expired', 'Complete visible', 'Photo clear'],
      },
      dl: {
        name: 'Driving License',
        requiredFields: ['License Number', 'Name', 'Valid From', 'Valid Until'],
        validityChecks: ['Not expired', 'Complete visible', 'Photo clear'],
      },
    };
    
    const req = documentRequirements[documentType];
    
    return `
You are a document verification expert. Analyze this ${req.name} image at ${fileUrl}.

TASK: Provide a detailed JSON analysis with:

1. isValid: boolean - Is the document acceptable for government verification?
2. confidenceScore: number 0-1 - How confident are you?
3. issues: array of strings - Any problems found (blur, cropped, expired, unreadable, fake_detected, etc.)
4. extractedData: object - Extract key fields: ${req.requiredFields.join(', ')}
5. suggestions: array of strings - Specific fixes needed

Check for:
- ${req.validityChecks.join('\n- ')}
- Image quality (blur, glare, shadows)
- Document completeness (all corners visible)
- Signs of tampering or fakes

Return ONLY valid JSON in this exact format:
{
  "isValid": true/false,
  "confidenceScore": 0.95,
  "issues": [],
  "extractedData": {
    "fieldName": "extracted value"
  },
  "suggestions": []
}
`;
  }
  
  /**
   * Parse AI response and extract structured data
   */
  _parseAIResponse(response, documentType) {
    try {
      // Try to find JSON in the response
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No JSON found in AI response');
      }
      
      const analysis = JSON.parse(jsonMatch[0]);
      
      return {
        isValid: analysis.isValid ?? false,
        confidenceScore: analysis.confidenceScore ?? 0,
        issues: analysis.issues ?? [],
        extractedData: analysis.extractedData ?? {},
        suggestions: analysis.suggestions ?? [],
      };
    } catch (error) {
      console.error('Failed to parse AI response:', error);
      
      // Fallback: make best guess from text response
      const text = response.toLowerCase();
      const hasValid = text.includes('valid') && !text.includes('invalid');
      const hasIssues = text.includes('blur') || text.includes('cropped') || 
                        text.includes('expired') || text.includes('unclear');
      
      return {
        isValid: hasValid && !hasIssues,
        confidenceScore: hasIssues ? 0.5 : 0.8,
        issues: hasIssues ? ['possible_quality_issues'] : [],
        extractedData: {},
        suggestions: hasIssues ? ['Please retake photo with better lighting'] : [],
      };
    }
  }
}

module.exports = new DocumentAIService();
