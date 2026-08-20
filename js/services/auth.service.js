// ==============================================================================
// AUTH SERVICE (Sign Up, Login, Logout, Session & Role Routing)
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
   * Sign out current user
   */
  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) console.warn('Sign out error:', error.message);
    window.location.href = window.location.origin + '/index.html';
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
      role: user.user_metadata?.role || 'job_seeker'
    };
  },

  /**
   * Redirect user to their appropriate portal dashboard based on role.
   * Always resolves from origin root so paths are never relative to current page.
   */
  async routeUserByRole() {
    const profile = await this.getCurrentProfile();
    const root = window.location.origin;

    if (!profile) {
      window.location.href = root + '/login.html';
      return;
    }

    if (profile.role === 'recruiter') {
      window.location.href = root + '/Recruiter%20Portal/dashboard.html';
    } else {
      window.location.href = root + '/Job%20Seeker%20Portal/dashboard.html';
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
