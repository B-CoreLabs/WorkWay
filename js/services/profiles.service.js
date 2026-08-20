// ==============================================================================
// PROFILES SERVICE (User profiles, skills, company employer records)
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const ProfileService = {
  /**
   * Get user profile by user ID
   */
  async getProfile(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Update user profile
   */
  async updateProfile(userId, updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Get or create company record for a recruiter
   */
  async getOrCreateCompany(recruiterId, companyData) {
    const { data: existing, error: fetchErr } = await supabase
      .from('companies')
      .select('*')
      .eq('created_by', recruiterId)
      .limit(1);

    if (existing && existing.length > 0) {
      return existing[0];
    }

    const slug = (companyData.name || 'company')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '') + '-' + Date.now();

    const { data, error } = await supabase
      .from('companies')
      .insert([
        {
          ...companyData,
          slug,
          created_by: recruiterId
        }
      ])
      .select()
      .single();

    if (error) throw error;
    return data;
  }
};
