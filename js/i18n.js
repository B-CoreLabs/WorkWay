// ==============================================================================
// WORKWAY BILINGUAL (EN / FR) INTERNATIONALIZATION (i18n) ENGINE
// ==============================================================================

export const translations = {
  en: {
    nav_find_jobs: "Find Jobs",
    nav_recruiters: "For Recruiters",
    nav_how_it_works: "How It Works",
    nav_resources: "Career Resources",
    nav_login: "Log In",
    nav_get_started: "Get Started",
    nav_dashboard: "Dashboard",
    nav_profile: "My Profile",
    nav_applications: "My Applications",
    nav_messages: "Messages",
    nav_notifications: "Notifications",
    nav_settings: "Settings",
    nav_admin: "Admin Panel",
    nav_logout: "Log Out",
    search_placeholder: "Job title, keywords, or skills...",
    location_placeholder: "Location (e.g. Yaoundé, Douala, Remote)...",
    search_btn: "Search Opportunities",
    filter_match: "Min Match %",
    filter_category: "All Industries",
    filter_type: "Employment Type",
    filter_experience: "Experience Level",
    filter_work_mode: "Work Mode",
    filter_salary: "Salary Range",
    job_view_details: "View Details",
    job_quick_apply: "Quick Apply",
    job_save: "Save Job",
    job_saved: "Saved",
    match_score: "Match Score",
    why_matches: "Why this matches you",
    copyright: "© 2026 WorkWay | All rights reserved | The WorkWay Team"
  },
  fr: {
    nav_find_jobs: "Trouver un emploi",
    nav_recruiters: "Pour Recruteurs",
    nav_how_it_works: "Comment ça marche",
    nav_resources: "Ressources Carrière",
    nav_login: "Connexion",
    nav_get_started: "Commencer",
    nav_dashboard: "Tableau de bord",
    nav_profile: "Mon Profil",
    nav_applications: "Mes Candidatures",
    nav_messages: "Messagerie",
    nav_notifications: "Notifications",
    nav_settings: "Paramètres",
    nav_admin: "Administration",
    nav_logout: "Déconnexion",
    search_placeholder: "Poste, mots-clés ou compétences...",
    location_placeholder: "Localisation (ex. Yaoundé, Douala, Télétravail)...",
    search_btn: "Rechercher",
    filter_match: "Score min %",
    filter_category: "Tous les secteurs",
    filter_type: "Type d'emploi",
    filter_experience: "Niveau d'expérience",
    filter_work_mode: "Mode de travail",
    filter_salary: "Fourchette de salaire",
    job_view_details: "Voir les détails",
    job_quick_apply: "Postuler",
    job_save: "Enregistrer",
    job_saved: "Enregistré",
    match_score: "Score de compatibilité",
    why_matches: "Pourquoi ce poste vous correspond",
    copyright: "© 2026 WorkWay | Tous droits réservés | L'équipe WorkWay"
  }
};

export const I18n = {
  getLanguage() {
    return localStorage.getItem('workway_lang') || 'en';
  },

  setLanguage(lang) {
    if (translations[lang]) {
      localStorage.setItem('workway_lang', lang);
      document.documentElement.lang = lang;
      this.translatePage();
    }
  },

  t(key) {
    const lang = this.getLanguage();
    return translations[lang]?.[key] || translations['en']?.[key] || key;
  },

  translatePage() {
    const elements = document.querySelectorAll('[data-i18n]');
    elements.forEach(el => {
      const key = el.getAttribute('data-i18n');
      const translation = this.t(key);
      if (translation) {
        if (el.tagName === 'INPUT' && el.getAttribute('placeholder')) {
          el.placeholder = translation;
        } else {
          el.textContent = translation;
        }
      }
    });
  }
};
