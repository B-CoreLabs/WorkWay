// ==============================================================================
// DYNAMIC NAVIGATION AUTH CONTROLLER (Header Auth State & Log Out)
// ==============================================================================
import { AuthService } from './services/auth.service.js';

document.addEventListener('DOMContentLoaded', async () => {
  try {
    const profile = await AuthService.getCurrentProfile();
    const navActions = document.querySelector('.nav-actions');

    if (!navActions) return;

    if (profile) {
      // User is logged in
      const portalUrl = profile.role === 'recruiter' 
        ? '/Recruiter%20Portal/dashboard.html' 
        : '/Job%20Seeker%20Portal/dashboard.html';
      const portalLabel = profile.role === 'recruiter' ? 'Recruiter Hub' : 'My Dashboard';
      const displayName = profile.full_name || profile.email.split('@')[0];
      const initial = displayName.charAt(0).toUpperCase();

      navActions.innerHTML = `
        <div class="nav-user-menu">
          <a href="${portalUrl}" class="nav-user-badge" title="Go to Dashboard">
            <span class="nav-user-avatar">${initial}</span>
            <span>${displayName}</span>
          </a>
          <a href="${portalUrl}" class="btn btn-secondary btn-sm">${portalLabel}</a>
          <button id="navLogoutBtn" class="btn btn-outline btn-sm" style="padding: 6px 14px; font-size: 0.75rem;">Log Out</button>
        </div>
      `;

      const logoutBtn = document.getElementById('navLogoutBtn');
      if (logoutBtn) {
        logoutBtn.addEventListener('click', async () => {
          await AuthService.signOut();
        });
      }
    }
  } catch (err) {
    console.debug('Auth check:', err.message);
  }
});
