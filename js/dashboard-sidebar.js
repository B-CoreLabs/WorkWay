// ==============================================================================
// WORKWAY — DASHBOARD SIDEBAR DYNAMIC CONTROLLER
// Syncs profile info, active links, mobile drawer, and logout across all pages
// ==============================================================================
import { AuthService } from './services/auth.service.js';

export class DashboardSidebar {
  static init() {
    this.highlightActivePage();
    this.initMobileDrawer();
    this.initLogout();
    this.syncUserProfile();
  }

  /* 1. Highlight Active Nav Link based on Current URL */
  static highlightActivePage() {
    const currentPath = window.location.pathname.split('/').pop() || 'jobseeker-dashboard.html';
    const links = document.querySelectorAll('.dash-sidebar .sidebar-link');

    links.forEach(link => {
      const href = link.getAttribute('href')?.split('/').pop();
      if (href && href === currentPath) {
        link.classList.add('active');
        link.setAttribute('aria-current', 'page');
      } else {
        link.classList.remove('active');
        link.removeAttribute('aria-current');
      }
    });
  }

  /* 2. Mobile Drawer Toggle and Overlay */
  static initMobileDrawer() {
    const sidebar = document.getElementById('dashSidebar');
    const toggleBtn = document.getElementById('sidebarToggle');
    const overlay = document.getElementById('sidebarOverlay');

    if (!sidebar) return;

    const setDrawerState = (isOpen) => {
      sidebar.classList.toggle('drawer-open', isOpen);
      if (overlay) overlay.classList.toggle('active', isOpen);
      if (toggleBtn) toggleBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    };

    if (toggleBtn) {
      toggleBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        const isOpen = sidebar.classList.contains('drawer-open');
        setDrawerState(!isOpen);
      });
    }

    if (overlay) {
      overlay.addEventListener('click', () => setDrawerState(false));
    }

    // Close on navigation link click inside mobile drawer
    sidebar.querySelectorAll('.sidebar-link').forEach(link => {
      link.addEventListener('click', () => setDrawerState(false));
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && sidebar.classList.contains('drawer-open')) {
        setDrawerState(false);
      }
    });
  }

  /* 3. Pinned Logout Button */
  static initLogout() {
    const logoutBtn = document.getElementById('sidebarLogoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', async () => {
        await AuthService.signOut();
      });
    }
  }

  /* 4. Sync User Info in Sidebar */
  static async syncUserProfile() {
    try {
      const profile = await AuthService.getCurrentProfile();
      if (!profile) return;

      // Update sidebar name
      const nameEl = document.getElementById('sidebarName');
      if (nameEl) {
        nameEl.textContent = profile.full_name || profile.email || 'User';
      }

      // Update sidebar avatar
      const avatarEl = document.getElementById('sidebarAvatar');
      if (avatarEl) {
        const initials = profile.full_name
          ? profile.full_name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()
          : (profile.email || 'JS').substring(0, 2).toUpperCase();

        if (profile.avatar_url) {
          avatarEl.innerHTML = `<img src="${profile.avatar_url}" alt="${profile.full_name || 'User'}" onerror="this.onerror=null; this.parentElement.textContent='${initials}';" />`;
        } else {
          avatarEl.textContent = initials;
        }
      }

      // Update welcome greet name if element exists
      const greetNameEl = document.getElementById('greetName');
      if (greetNameEl) {
        const firstName = (profile.full_name || profile.email || 'User').split(' ')[0];
        greetNameEl.textContent = firstName;
        greetNameEl.classList.remove('skeleton');
      }
    } catch (err) {
      console.warn('Could not sync sidebar user profile:', err);
    }
  }
}

// Auto-run when imported or DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => DashboardSidebar.init());
} else {
  DashboardSidebar.init();
}
