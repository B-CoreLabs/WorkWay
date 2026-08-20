// ==============================================================================
// JOBS SERVICE (Query, Filter, Create, Update, Delete Job Vacancies)
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const JobService = {
  /**
   * Fetch active jobs with optional search, jobType, remote filter
   */
  async getJobs({ search = '', jobType = 'all', isRemote = false } = {}) {
    let query = supabase
      .from('jobs')
      .select(`
        *,
        companies (
          id,
          name,
          slug,
          logo_url,
          location,
          industry
        )
      `)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (search && search.trim()) {
      query = query.ilike('title', `%${search.trim()}%`);
    }

    if (jobType && jobType !== 'all') {
      query = query.eq('job_type', jobType);
    }

    if (isRemote) {
      query = query.eq('is_remote', true);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  },

  /**
   * Get single job detail by ID
   */
  async getJobById(id) {
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        companies (
          id,
          name,
          slug,
          logo_url,
          website,
          description,
          location,
          industry
        )
      `)
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Post a new job (Recruiters only)
   */
  async createJob(jobData) {
    const { data, error } = await supabase
      .from('jobs')
      .insert([jobData])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Get all jobs posted by a specific recruiter
   */
  async getRecruiterJobs(recruiterId) {
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        companies (name, logo_url),
        job_applications (id, status)
      `)
      .eq('recruiter_id', recruiterId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  /**
   * Update job status or details
   */
  async updateJob(id, updates) {
    const { data, error } = await supabase
      .from('jobs')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Delete / Close job vacancy
   */
  async deleteJob(id) {
    const { error } = await supabase
      .from('jobs')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return true;
  }
};
