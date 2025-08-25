// Cart page functionality
$(document).ready(function() {
  console.log('Cart page JavaScript loaded');
  
  // Initialize cart page functionality
  initializeCartPage();
});

function initializeCartPage() {
  if (typeof $ === 'undefined') {
    console.error('jQuery is not loaded, retrying in 100ms');
    setTimeout(initializeCartPage, 100);
    return;
  }
  
  console.log('Initializing cart page functionality');
  
  // Set up event listeners for cart page elements
  setupCartPageEvents();
  
  // Initialize button states
  updateQuantityButtonStates();
}

function setupCartPageEvents() {
  // Quantity update buttons
  $(document).on('click', '.quantity-btn', function(e) {
    e.preventDefault();
    const productId = $(this).data('product-id');
    const change = $(this).data('change');
    updateQuantity(productId, change);
  });
  
  // Remove item buttons
  $(document).on('click', '.remove-item-btn', function(e) {
    e.preventDefault();
    const productId = $(this).data('product-id');
    removeItem(productId);
  });
  
  // Clear cart button
  $(document).on('click', '.clear-cart-btn', function(e) {
    e.preventDefault();
    clearCart();
  });
}

// Update quantity button states based on current quantities
function updateQuantityButtonStates() {
  $('.cart-item').each(function() {
    const $item = $(this);
    const productId = $item.data('product-id');
    const $quantityDisplay = $item.find('.quantity-display');
    const $minusBtn = $item.find('.quantity-btn[data-change="-1"]');
    const $plusBtn = $item.find('.quantity-btn[data-change="1"]');
    
    const currentQuantity = parseInt($quantityDisplay.text());
    
    // Disable minus button if quantity is 1
    if (currentQuantity <= 1) {
      $minusBtn.addClass('opacity-50 cursor-not-allowed').removeClass('cursor-pointer').prop('disabled', true);
    } else {
      $minusBtn.removeClass('opacity-50 cursor-not-allowed').addClass('cursor-pointer').prop('disabled', false);
    }
    
    // Always enable plus button
    $plusBtn.removeClass('opacity-50 cursor-not-allowed').addClass('cursor-pointer').prop('disabled', false);
  });
}

// Update quantity function
function updateQuantity(productId, change) {
  console.log('Updating quantity for product:', productId, 'change:', change);
  
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for updateQuantity');
    return;
  }
  
  const $item = $(`[data-product-id="${productId}"]`);
  const $quantityDisplay = $item.find('.quantity-display');
  const $minusBtn = $item.find('.quantity-btn[data-change="-1"]');
  
  if ($quantityDisplay.length === 0) {
    console.error('Quantity display element not found for product:', productId);
    return;
  }
  
  const currentQuantity = parseInt($quantityDisplay.text());
  const newQuantity = Math.max(1, currentQuantity + change);
  
  // Prevent decreasing below 1
  if (newQuantity < 1) {
    return;
  }
  
  console.log('Current quantity:', currentQuantity, 'New quantity:', newQuantity);
  
  // Disable minus button if new quantity will be 1
  if (newQuantity <= 1) {
    $minusBtn.addClass('opacity-50 cursor-not-allowed').removeClass('cursor-pointer').prop('disabled', true);
  } else {
    $minusBtn.removeClass('opacity-50 cursor-not-allowed').addClass('cursor-pointer').prop('disabled', false);
  }
  
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
      console.log('Update quantity success:', data);
      if (data.success) {
        // Update the quantity display
        $quantityDisplay.text(newQuantity);
        
        // Update button states
        if (newQuantity <= 1) {
          $minusBtn.addClass('opacity-50 cursor-not-allowed').removeClass('cursor-pointer').prop('disabled', true);
        } else {
          $minusBtn.removeClass('opacity-50 cursor-not-allowed').addClass('cursor-pointer').prop('disabled', false);
        }
        
        // Update cart totals
        updateCartTotals(data.cart_count, data.cart_total);
        
        // Show success message
        showNotification('Quantity updated successfully');
        
        // Reload page to show updated totals
        setTimeout(function() {
          location.reload();
        }, 1000);
      }
    },
    error: function(xhr, status, error) {
      console.error('Update quantity error:', error);
      showNotification('Error updating quantity', 'error');
      
      // Revert button states on error
      updateQuantityButtonStates();
    }
  });
}

// Remove item function
function removeItem(productId) {
  console.log('Removing item for product:', productId);
  
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for removeItem');
    return;
  }
  
  if (!confirm('Are you sure you want to remove this item from your cart?')) {
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
      console.log('Remove item success:', data);
      if (data.success) {
        // Remove the item from the DOM
        $(`[data-product-id="${productId}"]`).fadeOut(300, function() {
          $(this).remove();
          
          // Check if cart is empty
          if ($('.cart-item').length === 0) {
            location.reload(); // Reload to show empty cart message
          } else {
            // Update cart totals
            updateCartTotals(data.cart_count, data.cart_total);
            showNotification('Item removed from cart');
          }
        });
      }
    },
    error: function(xhr, status, error) {
      console.error('Remove item error:', error);
      showNotification('Error removing item', 'error');
    }
  });
}

// Clear cart function
function clearCart() {
  console.log('Clearing cart');
  
  if (typeof $ === 'undefined') {
    console.error('jQuery not available for clearCart');
    return;
  }
  
  if (!confirm('Are you sure you want to clear your entire cart?')) {
    return;
  }
  
  $.ajax({
    url: '/cart/clear',
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    success: function(data) {
      console.log('Clear cart success:', data);
      if (data.success) {
        showNotification('Cart cleared successfully');
        setTimeout(function() {
          location.reload(); // Reload to show empty cart
        }, 1000);
      }
    },
    error: function(xhr, status, error) {
      console.error('Clear cart error:', error);
      showNotification('Error clearing cart', 'error');
    }
  });
}

// Update cart totals
function updateCartTotals(count, total) {
  console.log('Updating cart totals - count:', count, 'total:', total);
  
  // Update cart count in header if it exists
  const $cartCount = $('#cart-count');
  if ($cartCount.length > 0) {
    $cartCount.text(count);
  }
  
  // Update cart total in header if it exists
  const $cartTotal = $('#cart-total');
  if ($cartTotal.length > 0) {
    $cartTotal.text(`₹${total}`);
  }
  
  // Update order summary totals
  const $subtotal = $('.order-summary-subtotal');
  if ($subtotal.length > 0) {
    $subtotal.text(`₹${total}`);
  }
  
  const $total = $('.order-summary-total');
  if ($total.length > 0) {
    $total.text(`₹${total}`);
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

// Show notification function
function showNotification(message, type = 'success') {
  const notification = document.createElement('div');
  notification.className = `fixed top-20 right-4 px-6 py-3 rounded-lg shadow-lg z-50 transform translate-x-full transition-transform duration-300 ${type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}`;
  notification.textContent = message;
  
  document.body.appendChild(notification);
  
  setTimeout(function() {
    notification.classList.remove('translate-x-full');
  }, 100);
  
  setTimeout(function() {
    notification.classList.add('translate-x-full');
    setTimeout(function() {
      notification.remove();
    }, 300);
  }, 3000);
}
