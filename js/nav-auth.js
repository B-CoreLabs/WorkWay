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
            <button type="button" class="user-menu-btn" id="userMenuBtn" aria-label="Open user menu">
              ${avatarMarkup}
              <span class="user-menu-name">${(profile.full_name || profile.email || 'User').split(' ')[0]}</span>
              <i class="fa-solid fa-chevron-down user-menu-chevron"></i>
            </button>
            <div class="user-dropdown" id="userDropdown" role="menu" aria-label="User menu">
              <div class="user-dropdown-header">
                <div style="display:flex; align-items:center; gap:12px;">
                  ${avatarMarkup}
                  <div style="flex:1; overflow:hidden;">
                    <strong style="font-size: 0.92rem; color: var(--text-primary); display:block; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${profile.full_name || 'User'}</strong>
                    <span style="font-size: 0.75rem; color: var(--brand-blue); font-weight:700;">${profile.role === 'recruiter' ? '🏢 Recruiter Portal' : '🎓 Job Seeker Portal'}</span>
                  </div>
                </div>
              </div>
              <div class="user-dropdown-divider"></div>
              <a href="${dashboardUrl}" class="dropdown-highlight-link" role="menuitem">
                <i class="fa-solid fa-house-laptop" style="font-size: 1.1rem;"></i>
                <div>
                  <strong style="font-size: 0.9rem; display:block;">Open My Dashboard</strong>
                  <small style="font-size: 0.72rem; color: var(--text-muted);">Overview, Analytics &amp; Stats</small>
                </div>
              </a>
              <div class="user-dropdown-divider"></div>
              <button type="button" id="logoutBtn" role="menuitem" style="color: #ef4444; font-weight:700;">
                <i class="fa-solid fa-right-from-bracket"></i> Sign Out
              </button>
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
            const isOpen = userDropdown.classList.toggle('show');
            userMenuBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
          });

          document.addEventListener('click', (e) => {
            if (!userDropdown.contains(e.target) && !userMenuBtn.contains(e.target)) {
              userDropdown.classList.remove('show');
              userMenuBtn.setAttribute('aria-expanded', 'false');
            }
          });

          document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && userDropdown.classList.contains('show')) {
              userDropdown.classList.remove('show');
              userMenuBtn.setAttribute('aria-expanded', 'false');
              userMenuBtn.focus();
            }
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
