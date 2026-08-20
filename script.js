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
   HEADER: solid background + shadow once the page is scrolled
   ========================================================= */
const siteHeader = document.querySelector(".site-header");

function updateHeaderOnScroll() {
  if (window.scrollY > 40) {
    siteHeader.classList.add("scrolled");
  } else {
    siteHeader.classList.remove("scrolled");
  }
}
window.addEventListener("scroll", updateHeaderOnScroll);
updateHeaderOnScroll();

/* =========================================================
   MOBILE NAV TOGGLE
   ========================================================= */
const navInner = document.querySelector(".nav-inner");
const navToggle = document.getElementById("navToggle");
const navLinksEl = document.getElementById("navLinks");

navToggle.addEventListener("click", () => {
  const isOpen = navInner.classList.toggle("menu-open");
  navToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
});

// Close the mobile menu automatically after tapping a nav link
navLinksEl.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    navInner.classList.remove("menu-open");
    navToggle.setAttribute("aria-expanded", "false");
  });
});

/* =========================================================
   SCROLL-REVEAL ANIMATIONS
   Adds the .reveal class to key elements at runtime, then
   fades/slides each one in the first time it enters view.
   ========================================================= */
const revealTargets = document.querySelectorAll(
  ".value-card, .problem-card, .problem-connector, .powering-text, .powering-paragraph, .final-cta-content, .problem-intro"
);
revealTargets.forEach((el) => el.classList.add("reveal"));

const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        revealObserver.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }
);
revealTargets.forEach((el) => revealObserver.observe(el));
