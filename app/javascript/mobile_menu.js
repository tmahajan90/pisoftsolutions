// Mobile menu functionality
$(document).ready(function() {
  const $mobileMenuButton = $('.mobile-menu-button');
  const $mobileMenu = $('.mobile-menu');
  
  $mobileMenuButton.on('click', function() {
    $mobileMenu.toggleClass('hidden');
  });
  
  // Close mobile menu when clicking on a link
  $mobileMenu.find('a').on('click', function() {
    $mobileMenu.addClass('hidden');
  });
  
  // Close mobile menu when clicking outside
  $(document).on('click', function(e) {
    if (!$(e.target).closest('.mobile-menu-button, .mobile-menu').length) {
      $mobileMenu.addClass('hidden');
    }
  });
});
