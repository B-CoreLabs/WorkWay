// ==============================================================================
// UNIVERSAL NAVIGATION, AUTH STATE, THEME & LANGUAGE CONTROLLER
// ==============================================================================
import { AuthService } from './services/auth.service.js';
import { I18n } from './i18n.js';

class NavigationController {
  constructor() {
    this.initTheme();
    this.initLanguage();
    this.initHeaderScroll();
    this.initMobileMenu();
    this.syncAuthState();
    this.highlightActiveLink();
  }

  /* 1. Theme Management (Light / Dark) */
  initTheme() {
    const savedTheme = localStorage.getItem('workway_theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);

    const themeToggleBtn = document.getElementById('themeToggleBtn');
    if (themeToggleBtn) {
      themeToggleBtn.innerHTML = savedTheme === 'dark' ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
      themeToggleBtn.addEventListener('click', () => this.toggleTheme());
    }
  }

  toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme') || 'light';
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('workway_theme', next);

    const themeToggleBtn = document.getElementById('themeToggleBtn');
    if (themeToggleBtn) {
      themeToggleBtn.innerHTML = next === 'dark' ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
    }
  }

  /* 2. Bilingual i18n Management */
  initLanguage() {
    const lang = I18n.getLanguage();
    document.documentElement.lang = lang;
    I18n.translatePage();

    const langSelect = document.getElementById('langSelect');
    if (langSelect) {
      langSelect.value = lang;
      langSelect.addEventListener('change', (e) => {
        I18n.setLanguage(e.target.value);
      });
    }
  }

  /* 3. Header Scroll Behavior */
  initHeaderScroll() {
    const header = document.querySelector('.site-header');
    if (!header) return;

    const onScroll = () => {
      if (window.scrollY > 30) {
        header.classList.add('scrolled');
      } else {
        header.classList.remove('scrolled');
      }
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* 4. Mobile Menu Toggle */
  initMobileMenu() {
    const navInner = document.querySelector('.nav-inner');
    const navToggle = document.getElementById('navToggle');
    const navLinks = document.getElementById('navLinks');

    if (navToggle && navInner) {
      navToggle.addEventListener('click', () => {
        const isOpen = navInner.classList.toggle('menu-open');
        navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      });
    }

    if (navLinks && navInner) {
      navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
          navInner.classList.remove('menu-open');
          if (navToggle) navToggle.setAttribute('aria-expanded', 'false');
        });
      });
    }
  }

  /* 5. Active Link Highlighting */
  highlightActiveLink() {
    const currentPath = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('.nav-links a');
    navLinks.forEach(link => {
      const href = link.getAttribute('href')?.split('/').pop();
      if (href && href === currentPath) {
        link.classList.add('active');
      }
    });
  }

  /* 6. Dynamic User Session Header Sync */
  async syncAuthState() {
    const navActions = document.querySelector('.nav-actions');
    if (!navActions) return;

    try {
      const profile = await AuthService.getCurrentProfile();

      if (profile) {
        // User is logged in: Render dynamic avatar dropdown
        const initials = profile.full_name
          ? profile.full_name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()
          : profile.email.substring(0, 2).toUpperCase();

        const dashboardUrl = profile.role === 'admin' 
          ? 'admin.html' 
          : profile.role === 'recruiter' 
            ? 'recruiter-dashboard.html' 
            : 'jobseeker-dashboard.html';

        navActions.innerHTML = `
          <div class="theme-lang-controls">
            <button id="themeToggleBtn" class="icon-btn" aria-label="Toggle Theme">
              <i class="fa-solid fa-${localStorage.getItem('workway_theme') === 'dark' ? 'sun' : 'moon'}"></i>
            </button>
            <select id="langSelect" class="lang-select" aria-label="Select Language">
              <option value="en">EN</option>
              <option value="fr">FR</option>
            </select>
          </div>

          <div class="user-menu-wrapper" id="userMenuWrapper">
            <button type="button" class="user-menu-btn" id="userMenuBtn">
              <div class="user-avatar-sm">${initials}</div>
              <span>${profile.full_name ? profile.full_name.split(' ')[0] : 'Account'}</span>
              <i class="fa-solid fa-chevron-down" style="font-size: 0.75rem;"></i>
            </button>
            <div class="user-dropdown" id="userDropdown">
              <div style="padding: 10px 18px 4px;">
                <strong style="font-size: 0.9rem; color: var(--text-primary); display:block;">${profile.full_name || 'User'}</strong>
                <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: capitalize;">${profile.role?.replace('_', ' ')}</span>
              </div>
              <div class="user-dropdown-divider"></div>
              <a href="${dashboardUrl}"><i class="fa-solid fa-chart-line"></i> Dashboard</a>
              ${profile.role === 'job_seeker' ? '<a href="profile.html"><i class="fa-solid fa-user"></i> My Profile</a>' : ''}
              ${profile.role === 'job_seeker' ? '<a href="my-applications.html"><i class="fa-solid fa-file-lines"></i> My Applications</a>' : ''}
              ${profile.role === 'recruiter' ? '<a href="manage-jobs.html"><i class="fa-solid fa-briefcase"></i> Manage Jobs</a>' : ''}
              ${profile.role === 'recruiter' ? '<a href="post-job.html"><i class="fa-solid fa-plus-circle"></i> Post a Job</a>' : ''}
              <a href="messages.html"><i class="fa-solid fa-comments"></i> Messages</a>
              <a href="notifications.html"><i class="fa-solid fa-bell"></i> Notifications</a>
              <a href="settings.html"><i class="fa-solid fa-gear"></i> Settings</a>
              <div class="user-dropdown-divider"></div>
              <button type="button" id="logoutBtn" style="color: #ef4444;"><i class="fa-solid fa-right-from-bracket"></i> Log Out</button>
            </div>
          </div>
        `;

        // Bind dropdown events
        const userMenuBtn = document.getElementById('userMenuBtn');
        const userDropdown = document.getElementById('userDropdown');
        const logoutBtn = document.getElementById('logoutBtn');

        if (userMenuBtn && userDropdown) {
          userMenuBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            userDropdown.classList.toggle('show');
          });

          document.addEventListener('click', () => {
            userDropdown.classList.remove('show');
          });
        }

        if (logoutBtn) {
          logoutBtn.addEventListener('click', async () => {
            await AuthService.signOut();
          });
        }

        // Rebind theme and lang controls inside navActions
        this.initTheme();
        this.initLanguage();

      } else {
        // Guest User: Standard Log In and Get Started buttons
        navActions.innerHTML = `
          <div class="theme-lang-controls">
            <button id="themeToggleBtn" class="icon-btn" aria-label="Toggle Theme">
              <i class="fa-solid fa-${localStorage.getItem('workway_theme') === 'dark' ? 'sun' : 'moon'}"></i>
            </button>
            <select id="langSelect" class="lang-select" aria-label="Select Language">
              <option value="en">EN</option>
              <option value="fr">FR</option>
            </select>
          </div>
          <a href="login.html" class="btn btn-secondary">Log In</a>
          <a href="signup.html" class="btn btn-primary">Get Started</a>
        `;
        this.initTheme();
        this.initLanguage();
      }
    } catch (err) {
      console.warn('Error synchronizing auth state:', err);
    }
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  new NavigationController();
});
