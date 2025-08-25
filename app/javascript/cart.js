// Cart functionality
let jqueryRetryCount = 0;
const MAX_JQUERY_RETRIES = 50; // 5 seconds max

function initializeCart() {
  if (typeof $ === 'undefined') {
    console.error('jQuery is not loaded, retrying in 100ms');
    setTimeout(initializeCart, 100);
    return;
  }
  
  // Now jQuery is available, proceed with initialization
  $(document).ready(function() {
    // Cart sidebar functionality
    const $cartSidebar = $('#cart-sidebar');
    const $cartOverlay = $('#cart-overlay');
    const $openCartBtn = $('#open-cart');
    const $closeCartBtn = $('#close-cart');
    
    // Only initialize cart functionality if cart elements exist
    if ($cartSidebar.length > 0 && $cartOverlay.length > 0 && $openCartBtn.length > 0 && $closeCartBtn.length > 0) {
      // Open cart
      $openCartBtn.on('click', function() {
        $cartSidebar.removeClass('translate-x-full');
        $cartOverlay.removeClass('hidden');
      });
      
      // Close cart
      $closeCartBtn.on('click', function() {
        $cartSidebar.addClass('translate-x-full');
        $cartOverlay.addClass('hidden');
      });
      
      // Close cart when clicking overlay
      $cartOverlay.on('click', function() {
        $cartSidebar.addClass('translate-x-full');
        $cartOverlay.addClass('hidden');
      });
    }
  });
}

// Update cart display
function updateCartDisplay(count, total) {
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for updateCartDisplay');
    return;
  }
  
  const $cartCount = $('#cart-count');
  const $cartTotal = $('#cart-total');
  
  if ($cartCount.length > 0) {
    $cartCount.text(count);
  }
  
  if ($cartTotal.length > 0) {
    $cartTotal.text(`₹${total}`);
  }
  
  // Update header cart count
  updateHeaderCartCount(count);
}

// Update header cart count
function updateHeaderCartCount(count) {
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for updateHeaderCartCount');
    return;
  }
  
  // Find the cart count span in the header
  const $headerCartCount = $('#header-cart-link span');
  
  if (count > 0) {
    // If count > 0, show or update the count badge
    if ($headerCartCount.length > 0) {
      $headerCartCount.text(count);
    } else {
      // Create the count badge if it doesn't exist
      $('#header-cart-link').append(`<span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">${count}</span>`);
    }
  } else {
    // If count is 0, remove the count badge
    $headerCartCount.remove();
  }
}

// Proceed to checkout
function proceedToCheckout() {
  window.location.href = '/checkout';
}

// Update quantity in cart
function updateQuantity(productId, change) {
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for updateQuantity');
    return;
  }
  
  const $quantityDisplay = $(`[data-product-id="${productId}"] .quantity-display`);
  
  if ($quantityDisplay.length === 0) {
    console.error('Quantity display element not found for product:', productId);
    return;
  }
  
  const currentQuantity = parseInt($quantityDisplay.text());
  const newQuantity = Math.max(1, currentQuantity + change);
  
  $.ajax({
    url: '/cart/update_quantity',
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    data: JSON.stringify({
      product_id: productId,
      quantity: newQuantity
    }),
    success: function(data) {
      if (data.success) {
        updateCartDisplay(data.cart_count, data.cart_total);
        location.reload(); // Refresh to show updated quantities
      }
    },
    error: function() {
      if (typeof showNotification === 'function') {
        showNotification('Error updating quantity', 'error');
      } else {
        console.error('Error updating quantity');
      }
    }
  });
}

// Remove item from cart
function removeItem(productId) {
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for removeItem');
    return;
  }
  
  $.ajax({
    url: '/cart/remove_item',
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    data: JSON.stringify({
      product_id: productId
    }),
    success: function(data) {
      if (data.success) {
        updateCartDisplay(data.cart_count, data.cart_total);
        location.reload(); // Refresh to show updated cart
      }
    },
    error: function() {
      if (typeof showNotification === 'function') {
        showNotification('Error removing item', 'error');
      } else {
        console.error('Error removing item');
      }
    }
  });
}

// Clear cart
function clearCart() {
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for clearCart');
    return;
  }
  
  if (confirm('Are you sure you want to clear your cart?')) {
    $.ajax({
      url: '/cart/clear',
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      success: function(data) {
        if (data.success) {
          updateCartDisplay(0, 0);
          location.reload(); // Refresh to show empty cart
        }
      },
      error: function() {
        if (typeof showNotification === 'function') {
          showNotification('Error clearing cart', 'error');
        } else {
          console.error('Error clearing cart');
        }
      }
    });
  }
}

// Initialize cart functionality when DOM is ready
function initializeCartOnReady() {
  if (typeof $ === 'undefined') {
    jqueryRetryCount++;
    if (jqueryRetryCount >= MAX_JQUERY_RETRIES) {
      console.error('jQuery failed to load after', MAX_JQUERY_RETRIES, 'retries. Cart functionality will be disabled.');
      return;
    }
    console.error('jQuery is not loaded, retrying in 100ms (attempt', jqueryRetryCount, 'of', MAX_JQUERY_RETRIES, ')');
    setTimeout(initializeCartOnReady, 100);
    return;
  }
  
  console.log('jQuery loaded successfully, initializing cart functionality');
  $(document).ready(function() {
    // Only initialize if we're on a page with cart elements
    if ($('#cart-sidebar').length > 0 || $('#open-cart').length > 0) {
      initializeCart();
    }
  });
}

// Start initialization
initializeCartOnReady();
