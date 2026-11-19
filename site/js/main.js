/* ============================================================
   SUPRAVAT DASH — MULTI-PAGE INTERACTIONS
   Vanilla JavaScript. Zero dependencies.
   ============================================================ */

'use strict';

/* ---- THEME INITIALIZATION ---- */
(function initTheme() {
  const stored = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const theme = stored || (prefersDark ? 'dark' : 'light');
  document.documentElement.setAttribute('data-theme', theme);
})();

// SVG Icons for Theme Toggle
const ICON_SUN = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>`;
const ICON_MOON = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`;

document.addEventListener('DOMContentLoaded', () => {

  /* ---- THEME CONTROLLER ---- */
  const themeToggle = document.getElementById('theme-toggle');
  const themeIcon   = document.getElementById('theme-icon');

  function updateThemeDisplay(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
    if (themeIcon) {
      themeIcon.innerHTML = theme === 'dark' ? ICON_SUN : ICON_MOON;
    }
    if (themeToggle) {
      themeToggle.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`);
    }
  }

  const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
  updateThemeDisplay(currentTheme);

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme');
      updateThemeDisplay(active === 'dark' ? 'light' : 'dark');
    });
  }

  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
    if (!localStorage.getItem('theme')) {
      updateThemeDisplay(e.matches ? 'dark' : 'light');
    }
  });

  /* ---- ACTIVE NAVIGATION HIGHLIGHTING (MULTI-PAGE) ---- */
  const path = window.location.pathname.replace(/\/index\.html$/, '/');
  const navLinks = document.querySelectorAll('.nav-links a, .nav-mobile a');

  navLinks.forEach(link => {
    const href = link.getAttribute('href');
    if (!href) return;
    const cleanHref = href.replace(/\/index\.html$/, '/');

    if (cleanHref === '/' && (path === '/' || path === '')) {
      link.classList.add('active');
    } else if (cleanHref !== '/' && path.startsWith(cleanHref)) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });

  /* ---- SCROLL STICKY NAVBAR ---- */
  const nav = document.getElementById('main-nav');
  const bttBtn = document.getElementById('back-to-top');

  const onScroll = () => {
    if (nav) {
      nav.classList.toggle('scrolled', window.scrollY > 30);
    }
    if (bttBtn) {
      bttBtn.classList.toggle('visible', window.scrollY > 400);
    }
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  /* ---- MOBILE HAMBURGER MENU ---- */
  const hamburger  = document.getElementById('nav-hamburger');
  const mobileMenu = document.getElementById('nav-mobile');

  if (hamburger && mobileMenu) {
    hamburger.addEventListener('click', () => {
      const open = mobileMenu.classList.toggle('open');
      hamburger.setAttribute('aria-expanded', open);
      hamburger.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    });

    document.addEventListener('click', e => {
      if (mobileMenu.classList.contains('open') &&
          !mobileMenu.contains(e.target) &&
          !hamburger.contains(e.target)) {
        mobileMenu.classList.remove('open');
        hamburger.setAttribute('aria-expanded', 'false');
      }
    });
  }

  /* ---- SCROLL REVEAL ANIMATIONS ---- */
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const reveals = document.querySelectorAll('.reveal');

  if (!prefersReduced && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px -50px 0px', threshold: 0.1 });

    reveals.forEach(el => observer.observe(el));
  } else {
    reveals.forEach(el => el.classList.add('visible'));
  }

  /* ---- BACK TO TOP ---- */
  if (bttBtn) {
    bttBtn.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  /* ---- PROJECT SCREENSHOT GALLERY & LIGHTBOX ---- */
  const viewportImg = document.getElementById('gallery-viewport-img');
  const stripThumbs = document.querySelectorAll('.gallery-strip-thumb');
  const lightbox    = document.getElementById('lightbox');
  const lightboxImg = document.getElementById('lightbox-img');
  const lightboxCap = document.getElementById('lightbox-caption');
  const lightboxClose = document.getElementById('lightbox-close');

  if (stripThumbs.length && viewportImg) {
    stripThumbs.forEach(thumb => {
      thumb.addEventListener('click', () => {
        const fullSrc = thumb.getAttribute('data-full') || thumb.querySelector('img')?.src;
        const caption = thumb.getAttribute('data-caption') || thumb.querySelector('img')?.alt || '';
        if (fullSrc) {
          viewportImg.src = fullSrc;
          viewportImg.alt = caption;
        }
        stripThumbs.forEach(t => t.classList.remove('active'));
        thumb.classList.add('active');
      });
    });
    stripThumbs[0]?.classList.add('active');
  }

  function openLightbox(src, caption) {
    if (!lightbox || !lightboxImg) return;
    lightboxImg.src = src;
    lightboxImg.alt = caption || '';
    if (lightboxCap) lightboxCap.textContent = caption || '';
    lightbox.classList.add('open');
    document.body.style.overflow = 'hidden';
    lightboxClose?.focus();
  }

  function closeLightbox() {
    if (!lightbox) return;
    lightbox.classList.remove('open');
    document.body.style.overflow = '';
    if (lightboxImg) lightboxImg.src = '';
  }

  const viewport = document.getElementById('gallery-viewport');
  if (viewport && viewportImg) {
    viewport.addEventListener('click', () => {
      openLightbox(viewportImg.src, viewportImg.alt);
    });
    viewport.setAttribute('role', 'button');
    viewport.setAttribute('tabindex', '0');
    viewport.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        openLightbox(viewportImg.src, viewportImg.alt);
      }
    });
  }

  if (lightboxClose) lightboxClose.addEventListener('click', closeLightbox);
  if (lightbox) {
    lightbox.addEventListener('click', e => {
      if (e.target === lightbox) closeLightbox();
    });
  }
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && lightbox?.classList.contains('open')) {
      closeLightbox();
    }
  });

  /* ---- DYNAMIC COPYRIGHT YEAR ---- */
  const yearEl = document.getElementById('copyright-year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();
});
