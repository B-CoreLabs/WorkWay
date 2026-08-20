// ==============================================================================
// STORAGE SERVICE (Upload and manage Resumes, Avatars, and Logos)
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const StorageService = {
  /**
   * Upload CV / Resume (PDF / DOCX) to the 'resumes' bucket
   */
  async uploadResume(userId, file) {
    const fileExt = file.name.split('.').pop();
    const fileName = `${userId}/${Date.now()}_resume.${fileExt}`;

    const { data, error } = await supabase.storage
      .from('resumes')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: true
      });

    if (error) {
      // Fallback: If bucket does not exist or has strict policies, generate temporary object URL or error info
      console.error('Storage upload error:', error.message);
      throw error;
    }

    const { data: publicUrlData } = supabase.storage
      .from('resumes')
      .getPublicUrl(fileName);

    return publicUrlData?.publicUrl || fileName;
  },

  /**
   * Upload Avatar or Company Logo to 'avatars' bucket
   */
  async uploadAvatar(userId, file) {
    const fileExt = file.name.split('.').pop();
    const fileName = `${userId}/${Date.now()}_avatar.${fileExt}`;

    const { data, error } = await supabase.storage
      .from('avatars')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: true
      });

    if (error) throw error;

    const { data: publicUrlData } = supabase.storage
      .from('avatars')
      .getPublicUrl(fileName);

    return publicUrlData?.publicUrl || '';
  }
};
