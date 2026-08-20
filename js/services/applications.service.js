// ==============================================================================
// APPLICATIONS SERVICE (Submit applications, get candidate pipeline, update ATS status)
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const ApplicationService = {
  /**
   * Submit application for a job
   */
  async applyForJob({ jobId, applicantId, resumeUrl, coverLetter }) {
    const { data, error } = await supabase
      .from('job_applications')
      .insert([
        {
          job_id: jobId,
          applicant_id: applicantId,
          resume_url: resumeUrl,
          cover_letter: coverLetter,
          status: 'applied'
        }
      ])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * Get all applications submitted by a job seeker
   */
  async getSeekerApplications(applicantId) {
    const { data, error } = await supabase
      .from('job_applications')
      .select(`
        *,
        jobs (
          id,
          title,
          location,
          job_type,
          is_remote,
          salary_min,
          salary_max,
          companies (
            id,
            name,
            logo_url
          )
        )
      `)
      .eq('applicant_id', applicantId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  /**
   * Get all applications for a specific recruiter's posted job
   */
  async getJobApplicants(jobId) {
    const { data, error } = await supabase
      .from('job_applications')
      .select(`
        *,
        profiles (
          id,
          full_name,
          email,
          headline,
          avatar_url,
          resume_url,
          skills,
          experience_years,
          location
        )
      `)
      .eq('job_id', jobId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  /**
   * Update applicant status in ATS pipeline ('reviewing', 'shortlisted', 'interviewing', 'rejected', 'offered', 'hired')
   */
  async updateApplicationStatus(applicationId, newStatus) {
    const { data, error } = await supabase
      .from('job_applications')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', applicationId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
};
