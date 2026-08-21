// ==============================================================================
// AUTH SERVICE (Sign Up, Login, OAuth, Password Reset, Role Routing & Sessions)
// ==============================================================================
import { supabase } from '../supabase-config.js';

export const AuthService = {
  /**
   * Register a new user with metadata role ('job_seeker' or 'recruiter')
   */
  async signUp({ email, password, fullName, role = 'job_seeker' }) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: role
        }
      }
    });

    if (error) throw error;
    return data;
  },

  /**
   * Sign in with email and password
   */
  async signIn({ email, password }) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;
    return data;
  },

  /**
   * Sign in with OAuth provider (e.g. 'google', 'linkedin_oidc')
   */
  async signInWithOAuth(provider = 'google', role = null) {
    if (role) {
      localStorage.setItem('workway_oauth_desired_role', role);
    }
    const currentFolder = window.location.href.split('?')[0].split('#')[0].replace(/\/[^/]*$/, '/');
    const redirectUrl = `${currentFolder}login.html`;
    const providerKey = provider === 'linkedin' ? 'linkedin_oidc' : provider;

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: providerKey,
      options: {
        redirectTo: redirectUrl,
        queryParams: {
          access_type: 'offline',
          prompt: 'consent'
        }
      }
    });

    if (error) throw error;
    return data;
  },

  /**
   * Request password reset email
   */
  async resetPasswordForEmail(email) {
    const currentFolder = window.location.href.split('?')[0].split('#')[0].replace(/\/[^/]*$/, '/');
    const resetRedirect = `${currentFolder}reset-password.html`;
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: resetRedirect
    });

    if (error) throw error;
    return data;
  },

  /**
   * Update password for user with active session/recovery token
   */
  async updateUserPassword(newPassword) {
    const { data, error } = await supabase.auth.updateUser({
      password: newPassword
    });

    if (error) throw error;
    return data;
  },

  /**
   * Sign out current user
   */
  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) console.warn('Sign out error:', error.message);
    window.location.href = 'index.html';
  },

  /**
   * Get the current active session
   */
  async getSession() {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    return session;
  },

  /**
   * Get current user and their profile record
   */
  async getCurrentProfile() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (error && error.code !== 'PGRST116') {
      console.warn('Could not fetch user profile:', error.message);
    }

    return profile || {
      id: user.id,
      email: user.email,
      full_name: user.user_metadata?.full_name || user.email.split('@')[0],
      role: user.user_metadata?.role || 'job_seeker',
      theme_preference: 'light',
      language_preference: 'en'
    };
  },

  /**
   * Check if recruiter has an associated company profile
   */
  async getRecruiterCompany(userId) {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('created_by', userId)
      .limit(1);

    if (error || !data || data.length === 0) return null;
    return data[0];
  },

  /**
   * Redirect user to their appropriate portal dashboard based on role.
   */
  async routeUserByRole() {
    const profile = await this.getCurrentProfile();

    if (!profile) {
      window.location.href = 'login.html';
      return;
    }

    if (profile.role === 'admin') {
      window.location.href = 'admin.html';
    } else if (profile.role === 'recruiter') {
      const company = await this.getRecruiterCompany(profile.id);
      if (!company) {
        window.location.href = 'recruiter-onboarding.html';
      } else {
        window.location.href = 'recruiter-dashboard.html';
      }
    } else {
      window.location.href = 'jobseeker-dashboard.html';
    }
  },

  /**
   * Listen to auth state changes
   */
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange((event, session) => {
      callback(event, session);
    });
  }
};
