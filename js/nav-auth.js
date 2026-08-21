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

        const avatarMarkup = profile.avatar_url
          ? `<img src="${profile.avatar_url}" alt="Avatar" style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover; border: 1.5px solid var(--brand-gold);" onerror="this.onerror=null; this.parentElement.innerHTML='<div class=\\'user-avatar-sm\\'>${initials}</div>';" />`
          : `<div class="user-avatar-sm">${initials}</div>`;

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
            <button type="button" class="user-menu-btn" id="userMenuBtn" aria-label="Open Dashboard Hub">
              <div class="dashboard-hub-pill">
                <i class="fa-solid fa-gauge-high"></i>
                <span>Dashboard</span>
              </div>
              ${avatarMarkup}
              <i class="fa-solid fa-chevron-down" style="font-size: 0.75rem;"></i>
            </button>
            <div class="user-dropdown" id="userDropdown">
              <div class="user-dropdown-header">
                <div style="display:flex; align-items:center; gap:12px;">
                  ${avatarMarkup}
                  <div style="flex:1; overflow:hidden;">
                    <strong style="font-size: 0.92rem; color: var(--text-primary); display:block; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${profile.full_name || 'User'}</strong>
                    <span style="font-size: 0.75rem; color: var(--brand-blue); font-weight:700; text-transform: capitalize;">${profile.role === 'recruiter' ? '🏢 Recruiter Portal' : '🎓 Job Seeker Portal'}</span>
                  </div>
                </div>
              </div>
              <div class="user-dropdown-divider"></div>

              <a href="${dashboardUrl}" class="dropdown-highlight-link">
                <i class="fa-solid fa-house-laptop" style="font-size: 1.1rem;"></i>
                <div>
                  <strong style="font-size: 0.9rem; display:block;">Open My Dashboard</strong>
                  <small style="font-size: 0.72rem; color: var(--text-muted);">Overview, Analytics &amp; Stats</small>
                </div>
              </a>
              <div class="user-dropdown-divider"></div>

              <div class="dropdown-section-title">PORTAL &amp; TOOLS</div>
              ${profile.role === 'recruiter' ? `
                <a href="post-job.html"><i class="fa-solid fa-circle-plus" style="color:#22c55e;"></i> Post a New Job</a>
                <a href="manage-jobs.html"><i class="fa-solid fa-briefcase"></i> Manage Job Listings</a>
                <a href="candidate-search.html"><i class="fa-solid fa-users-viewfinder" style="color:var(--brand-blue);"></i> AI Candidate Search</a>
                <a href="recruiter-onboarding.html"><i class="fa-solid fa-building"></i> Company Profile</a>
              ` : `
                <a href="my-applications.html"><i class="fa-solid fa-file-signature" style="color:var(--brand-blue);"></i> My Applications</a>
                <a href="saved-jobs.html"><i class="fa-solid fa-bookmark" style="color:var(--brand-gold);"></i> Saved Jobs</a>
                <a href="profile.html"><i class="fa-solid fa-user-circle"></i> My Profile &amp; Photo</a>
                <a href="profile-setup.html"><i class="fa-solid fa-id-card"></i> Profile Setup Wizard</a>
                <a href="career-assessment.html"><i class="fa-solid fa-brain" style="color:#8b5cf6;"></i> AI Career Assessment</a>
                <a href="resume-analysis.html"><i class="fa-solid fa-wand-magic-sparkles" style="color:#ec4899;"></i> AI Resume &amp; ATS Score</a>
              `}

              <div class="user-dropdown-divider"></div>
              <div class="dropdown-section-title">COMMUNICATION</div>
              <a href="messages.html"><i class="fa-solid fa-comments"></i> Messages &amp; Chat</a>
              <a href="notifications.html"><i class="fa-solid fa-bell"></i> Notifications</a>

              <div class="user-dropdown-divider"></div>
              <div class="dropdown-section-title">SECURITY &amp; SETTINGS</div>
              <a href="2fa-setup.html"><i class="fa-solid fa-shield-halved" style="color:#10b981;"></i> 2-Factor Authentication</a>
              <a href="forgot-password.html"><i class="fa-solid fa-key"></i> Reset Password</a>
              <div class="user-dropdown-divider"></div>
              <button type="button" id="logoutBtn" style="color: #ef4444; font-weight:700;"><i class="fa-solid fa-right-from-bracket"></i> Sign Out</button>
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
        // Guest User: Portals Explorer + Log In + Get Started
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
