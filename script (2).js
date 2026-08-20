/* =========================================================
   HERO SWIPER INITIALIZATION & TAB CONTROLS
   ========================================================= */
const sliderTabs = document.querySelectorAll(".slider-tab");

const swiper = new Swiper(".slider-container", {
  effect: "fade",
  speed: 1300,
  autoplay: {
    delay: 4000,
    disableOnInteraction: false,
  },
});

function updateActiveTab(index) {
  sliderTabs.forEach((tab, tabIndex) => {
    tab.classList.toggle("active", tabIndex === index);
  });
}

sliderTabs.forEach((tab, index) => {
  tab.addEventListener("click", () => {
    swiper.slideTo(index);
    updateActiveTab(index);
    swiper.autoplay.start();
  });
});

swiper.on("slideChange", () => {
  updateActiveTab(swiper.activeIndex);
});

updateActiveTab(swiper.activeIndex);

/* =========================================================
   INITIAL LOAD STATE (ANTI-FLASH SYSTEM)
   Eliminates the flash of unstyled hero text and Swiper layout
   by waiting for fonts & DOM before revealing content smoothly.
   ========================================================= */
function markPageReady() {
  document.documentElement.classList.remove("is-loading");
  document.body.classList.remove("is-loading");
}

const fontPromise = document.fonts ? document.fonts.ready : Promise.resolve();
const domPromise = new Promise((resolve) => {
  if (document.readyState === "complete" || document.readyState === "interactive") {
    resolve();
  } else {
    window.addEventListener("DOMContentLoaded", resolve, { once: true });
  }
});

// Remove loading state once fonts & DOM are ready, with a 600ms safety timeout
const safetyTimeout = setTimeout(markPageReady, 600);

Promise.all([fontPromise, domPromise]).then(() => {
  clearTimeout(safetyTimeout);
  markPageReady();
});

/* =========================================================
   HEADER: Scrolled state toggle
   ========================================================= */
const siteHeader = document.querySelector(".site-header");

function updateHeaderOnScroll() {
  if (siteHeader) {
    if (window.scrollY > 30) {
      siteHeader.classList.add("scrolled");
    } else {
      siteHeader.classList.remove("scrolled");
    }
  }
}

window.addEventListener("scroll", updateHeaderOnScroll, { passive: true });
updateHeaderOnScroll();

/* =========================================================
   MOBILE NAV TOGGLE
   ========================================================= */
const navInner = document.querySelector(".nav-inner");
const navToggle = document.getElementById("navToggle");
const navLinksEl = document.getElementById("navLinks");

if (navToggle && navInner) {
  navToggle.addEventListener("click", () => {
    const isOpen = navInner.classList.toggle("menu-open");
    navToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
  });
}

if (navLinksEl && navInner) {
  navLinksEl.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      navInner.classList.remove("menu-open");
      if (navToggle) {
        navToggle.setAttribute("aria-expanded", "false");
      }
    });
  });
}

/* =========================================================
   SCROLL-REVEAL INTERSECTION OBSERVER
   ========================================================= */
const revealElements = document.querySelectorAll(".reveal");

if ("IntersectionObserver" in window) {
  const revealObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    {
      threshold: 0.15,
      rootMargin: "0px 0px -10% 0px",
    }
  );

  revealElements.forEach((el) => revealObserver.observe(el));
} else {
  // Fallback for older browsers
  revealElements.forEach((el) => el.classList.add("is-visible"));
}