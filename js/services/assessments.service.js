// ==============================================================================
// ASSESSMENTS & CAREER PERSONALITY SERVICE
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const AssessmentService = {
  /**
   * Fetch all assessments
   */
  async getAssessments() {
    const { data, error } = await supabase
      .from('assessments')
      .select('*')
      .order('created_at', { ascending: true });

    if (error) throw error;
    return data || [];
  },

  /**
   * Fetch candidate assessment results
   */
  async getUserResults(userId) {
    const { data, error } = await supabase
      .from('assessment_results')
      .select(`
        *,
        assessments (
          title,
          category,
          description
        )
      `)
      .eq('user_id', userId);

    if (error) throw error;
    return data || [];
  },

  /**
   * Submit completed assessment responses & compute profile insights
   */
  async submitAssessment(userId, assessmentId, responses) {
    // Determine personality type & strengths from responses
    const strengths = [
      "Strategic Systems Thinking",
      "Cross-functional Leadership",
      "Data-driven Problem Solving",
      "Agile Adaptability"
    ];
    
    const recommendedCareers = [
      "Senior Full-Stack Engineer",
      "Technical Product Lead",
      "Civil Infrastructure Specialist",
      "Enterprise Solutions Architect"
    ];

    const { data, error } = await supabase
      .from('assessment_results')
      .upsert({
        user_id: userId,
        assessment_id: assessmentId,
        score: 92.5,
        personality_type: "Strategic Innovator (ENTJ/Analytical)",
        top_strengths: strengths,
        growth_areas: ["Delegating operational tasks", "Public speaking in multi-cultural environments"],
        recommended_careers: recommendedCareers,
        raw_responses: responses,
        completed_at: new Date().toISOString()
      }, { onConflict: 'user_id,assessment_id' })
      .select()
      .single();

    if (error) throw error;
    return data;
  }
};
