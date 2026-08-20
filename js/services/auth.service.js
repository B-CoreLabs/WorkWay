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
    // Use relative path so it works on localhost AND hosted domains
    const base = window.location.pathname.replace(/\/[^/]*$/, '');
    window.location.href = base + '/index.html';
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
   * Uses a base-path-aware redirect to work on localhost, file servers & production.
   */
  async routeUserByRole() {
    const profile = await this.getCurrentProfile();

    // Compute root of the project regardless of current page depth
    const pathParts = window.location.pathname.split('/');
    // Find the WorkWay root by going up until we're at project root
    let rootPath = '';
    for (let i = pathParts.length - 1; i >= 0; i--) {
      if (pathParts[i].toLowerCase().includes('portal') || pathParts[i] === '') {
        continue;
      }
      rootPath = pathParts.slice(0, i + 1).join('/');
      break;
    }
    if (!rootPath) rootPath = '';

    if (!profile) {
      window.location.href = rootPath + '/login.html';
      return;
    }

    if (profile.role === 'recruiter') {
      window.location.href = rootPath + '/Recruiter%20Portal/dashboard.html';
    } else {
      window.location.href = rootPath + '/Job%20Seeker%20Portal/dashboard.html';
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
