// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
// Import other modules after jQuery is loaded
import "./cart"
import "./mobile_menu"
import "./products"
import "./product_detail"
import "./cart_page"

// Handle DELETE method links for Rails 7
document.addEventListener('DOMContentLoaded', function() {
  // Handle method: :delete links
  document.addEventListener('click', function(e) {
    if (e.target.matches('[data-method="delete"]') || e.target.closest('[data-method="delete"]')) {
      e.preventDefault();
      const link = e.target.matches('[data-method="delete"]') ? e.target : e.target.closest('[data-method="delete"]');
      const url = link.href;
      const confirmMessage = link.dataset.confirm;
      
      if (confirmMessage && !confirm(confirmMessage)) {
        return;
      }
      
      // Create a form and submit it
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = url;
      
      const methodInput = document.createElement('input');
      methodInput.type = 'hidden';
      methodInput.name = '_method';
      methodInput.value = 'DELETE';
      
      const csrfInput = document.createElement('input');
      csrfInput.type = 'hidden';
      csrfInput.name = 'authenticity_token';
      csrfInput.value = document.querySelector('meta[name="csrf-token"]').content;
      
      form.appendChild(methodInput);
      form.appendChild(csrfInput);
      document.body.appendChild(form);
      form.submit();
    }
  });
});
