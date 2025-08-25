// Product Detail page functionality
$(document).ready(function() {
  // Global variables
  let validityOptions = [];
  
  // Initialize product detail functionality
  function initializeProductDetail() {
    console.log('=== Initializing Product Detail ===');
    
    // Get validity options from the page
    const validityOptionsElement = document.getElementById('validity-options-data');
    if (validityOptionsElement) {
      validityOptions = JSON.parse(validityOptionsElement.textContent);
    }
    
    console.log('Validity options:', validityOptions);
    
    // Set up the change event listener for plan selection
    const selectElement = document.getElementById('plan-select');
    if (selectElement) {
      console.log('Select element found, adding change listener');
      selectElement.addEventListener('change', function() {
        console.log('=== Dropdown changed ===');
        console.log('New value:', this.value);
        updatePlanDetails();
      });
      
      // Initialize with current selection
      updatePlanDetails();
    } else {
      console.error('Select element not found');
    }
  }
  
  // Update plan details based on selection
  function updatePlanDetails() {
    console.log('=== updatePlanDetails called ===');
    
    if (validityOptions.length === 0) {
      console.error('No validity options available');
      return;
    }
    
    // Get the selected value
    const selectElement = document.getElementById('plan-select');
    const selectedIndex = parseInt(selectElement.value) || 0;
    const selectedPlan = validityOptions[selectedIndex];
    
    console.log('Selected index:', selectedIndex);
    console.log('Selected plan:', selectedPlan);
    
    // Get the elements
    const planNameEl = document.getElementById('plan-name');
    const planPriceEl = document.getElementById('plan-price');
    const planDescEl = document.getElementById('plan-description');
    const planIconEl = document.getElementById('plan-icon');
    const addToCartBtn = document.getElementById('add-to-cart-btn');
    const trialStatusEl = document.getElementById('trial-status');
    
    console.log('Elements found:', {
      planName: !!planNameEl,
      planPrice: !!planPriceEl,
      planDesc: !!planDescEl,
      planIcon: !!planIconEl,
      addToCartBtn: !!addToCartBtn,
      trialStatus: !!trialStatusEl
    });
    
    // Update the content
    if (planNameEl && planPriceEl && planDescEl && planIconEl) {
      // Update plan name
      planNameEl.textContent = selectedPlan.label;
      console.log('Updated plan name to:', selectedPlan.label);
      
      // Update plan price
      planPriceEl.textContent = '₹' + selectedPlan.price;
      console.log('Updated plan price to: ₹' + selectedPlan.price);
      
      // Update description and icon
      if (selectedPlan.type === 'lifetime') {
        planDescEl.textContent = 'Unlimited access forever';
        planIconEl.className = 'fas fa-infinity text-xl text-blue-600';
      } else if (selectedPlan.trial) {
        planDescEl.textContent = '1-day trial access';
        planIconEl.className = 'fas fa-gift text-xl text-green-600';
      } else {
        planDescEl.textContent = 'Full access for ' + selectedPlan.duration + ' ' + selectedPlan.type;
        planIconEl.className = 'fas fa-clock text-xl text-blue-600';
      }
      
      // Handle trial logic
      if (selectedPlan.trial) {
        if (selectedPlan.trial_used) {
          // Trial already used
          if (addToCartBtn) {
            addToCartBtn.disabled = true;
            addToCartBtn.textContent = 'Trial Already Used';
            addToCartBtn.className = 'flex-1 bg-gray-400 text-white py-3 px-6 rounded-lg font-semibold text-lg cursor-not-allowed';
          }
          if (trialStatusEl) {
            trialStatusEl.classList.remove('hidden');
          }
        } else if (selectedPlan.can_use_trial) {
          // Trial available
          if (addToCartBtn) {
            addToCartBtn.disabled = false;
            addToCartBtn.textContent = 'Start Trial';
            addToCartBtn.className = 'flex-1 bg-green-600 hover:bg-green-700 text-white py-3 px-6 rounded-lg font-semibold text-lg transition duration-300 flex items-center justify-center';
          }
          if (trialStatusEl) {
            trialStatusEl.classList.remove('hidden');
          }
        }
      } else {
        // Not a trial option
        if (addToCartBtn) {
          addToCartBtn.disabled = false;
          addToCartBtn.innerHTML = '<i class="fas fa-shopping-cart mr-2"></i>Add to Cart';
          addToCartBtn.className = 'flex-1 bg-blue-600 hover:bg-blue-700 text-white py-3 px-6 rounded-lg font-semibold text-lg transition duration-300 flex items-center justify-center';
        }
        if (trialStatusEl) {
          trialStatusEl.classList.add('hidden');
        }
      }
      
      console.log('Successfully updated all plan details');
    } else {
      console.error('Some elements not found');
    }
  }
  
  // Add to cart function
  window.addToCartWithValidity = function(productId) {
    console.log('Adding to cart with validity:', productId);
    
    if (validityOptions.length === 0) {
      console.error('No validity options available');
      showNotification('Error: No plan options available', 'error');
      return;
    }
    
    const selectElement = document.getElementById('plan-select');
    const selectedIndex = parseInt(selectElement.value) || 0;
    const selectedPlan = validityOptions[selectedIndex];
    
    console.log('Selected plan for cart:', selectedPlan);
    
    // Check if trial is already used
    if (selectedPlan.trial && selectedPlan.trial_used) {
      showNotification('You have already used the trial for this product', 'error');
      return;
    }
    
    $.ajax({
      url: '/cart/add_item',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      data: JSON.stringify({
        product_id: productId,
        quantity: 1,
        validity: selectedPlan.type,
        duration: selectedPlan.duration,
        price: selectedPlan.price,
        is_trial: selectedPlan.trial || false
      }),
      success: function(data) {
        console.log('Add to cart success:', data);
        if (data.success) {
          showNotification(data.message);
          updateCartDisplay(data.cart_count, data.cart_total);
          
          // If this was a trial, update the UI to show it's been used
          if (selectedPlan.trial && data.trial_marked) {
            selectedPlan.trial_used = true;
            selectedPlan.can_use_trial = false;
            updatePlanDetails();
          }
        } else {
          showNotification(data.message, 'error');
        }
      },
      error: function(xhr, status, error) {
        console.error('Add to cart error:', error);
        showNotification('Error adding item to cart', 'error');
      }
    });
  };
  
  // Contact sales function
  window.contactSales = function() {
    window.location.href = '/contact';
  };
  
  // Show notification function
  window.showNotification = function(message, type = 'success') {
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
  };
  
  // Update cart display function
  window.updateCartDisplay = function(count, total) {
    const cartCountEl = document.getElementById('cart-count');
    const cartTotalEl = document.getElementById('cart-total');
    
    if (cartCountEl) cartCountEl.textContent = count;
    if (cartTotalEl) cartTotalEl.textContent = `₹${total}`;
    
    // Update header cart count
    updateHeaderCartCount(count);
  };

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
  
  // Test function for debugging
  window.testUpdate = function() {
    console.log('=== Test Update Function Called ===');
    const selectElement = document.getElementById('plan-select');
    console.log('Current dropdown value:', selectElement ? selectElement.value : 'No select element');
    updatePlanDetails();
  };
  
  // Initialize if we're on a product detail page
  if ($('#plan-select').length > 0) {
    initializeProductDetail();
  }
});
