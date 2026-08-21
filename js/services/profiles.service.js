// ==============================================================================
// PROFILES & CANDIDATE DATA SERVICE
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const ProfileService = {
  /**
   * Fetch full candidate profile including extended preferences, skills, experience, education, and resumes
   */
  async getCandidateFullProfile(userId) {
    const [profileRes, detailsRes, skillsRes, expRes, eduRes, resumesRes] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', userId).single(),
      supabase.from('candidate_profiles').select('*').eq('user_id', userId).maybeSingle(),
      supabase.from('candidate_skills').select('*').eq('user_id', userId),
      supabase.from('candidate_experience').select('*').eq('user_id', userId).order('start_date', { ascending: false }),
      supabase.from('candidate_education').select('*').eq('user_id', userId).order('start_year', { ascending: false }),
      supabase.from('candidate_resumes').select('*').eq('user_id', userId).order('created_at', { ascending: false })
    ]);

    return {
      profile: profileRes.data || null,
      details: detailsRes.data || null,
      skills: skillsRes.data || [],
      experience: expRes.data || [],
      education: eduRes.data || [],
      resumes: resumesRes.data || []
    };
  },

  /**
   * Save / Update core profile
   */
  async updateProfile(userId, data) {
    const { data: profile, error } = await supabase
      .from('profiles')
      .update(data)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return profile;
  },

  /**
   * Save / Upsert candidate extended details
   */
  async upsertCandidateDetails(userId, details) {
    const { data, error } = await supabase
      .from('candidate_profiles')
      .upsert({ user_id: userId, ...details }, { onConflict: 'user_id' })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Add normalized skills
   */
  async saveSkills(userId, skillsList) {
    // Delete existing and insert new
    await supabase.from('candidate_skills').delete().eq('user_id', userId);
    
    if (!skillsList || skillsList.length === 0) return [];
    
    const rows = skillsList.map(s => ({
      user_id: userId,
      skill_name: typeof s === 'string' ? s : s.name,
      proficiency_level: s.level || 'intermediate',
      years_experience: s.years || 1
    }));

    const { data, error } = await supabase
      .from('candidate_skills')
      .insert(rows)
      .select();

    if (error) throw error;
    return data;
  },

  /**
   * Add experience entry
   */
  async addExperience(userId, exp) {
    const { data, error } = await supabase
      .from('candidate_experience')
      .insert([{ user_id: userId, ...exp }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Delete experience entry
   */
  async deleteExperience(id) {
    const { error } = await supabase.from('candidate_experience').delete().eq('id', id);
    if (error) throw error;
    return true;
  },

  /**
   * Add education entry
   */
  async addEducation(userId, edu) {
    const { data, error } = await supabase
      .from('candidate_education')
      .insert([{ user_id: userId, ...edu }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Add / Upload resume version
   */
  async addResumeVersion(userId, resumeData) {
    const { data, error } = await supabase
      .from('candidate_resumes')
      .insert([{ user_id: userId, ...resumeData }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Set primary resume
   */
  async setPrimaryResume(userId, resumeId) {
    await supabase.from('candidate_resumes').update({ is_primary: false }).eq('user_id', userId);
    const { data, error } = await supabase
      .from('candidate_resumes')
      .update({ is_primary: true })
      .eq('id', resumeId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
};
