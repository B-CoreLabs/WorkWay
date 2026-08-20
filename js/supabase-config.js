// ==============================================================================
// WORKWAY SUPABASE CLIENT INITIALIZATION
// ==============================================================================
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

export const SUPABASE_URL = "https://mdzjpybrzoyxixhrydbf.supabase.co";
export const SUPABASE_ANON_KEY = "sb_publishable_rV4ivdoK7vh7OinTC60iJg_09Tt_eMA";

// Initialize the Supabase Client with persistent session storage and auto-token refresh
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  }
});
