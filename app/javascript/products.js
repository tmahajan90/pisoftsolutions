// Products page functionality
// Wait for both DOM and jQuery to be ready
function initializeProducts() {
  if (typeof $ === 'undefined') {
    console.error('jQuery is not loaded, retrying in 100ms');
    setTimeout(initializeProducts, 100);
    return;
  }
  
  // Now jQuery is available, proceed with initialization
  // Category filter
  $('#category-filter').on('change', function() {
    filterProducts();
  });
  
  // Sort options
  $('#sort-options').on('change', function() {
    sortProducts();
  });
  
  // View toggle
  $('#grid-view').on('click', function() {
    setView('grid');
  });
  
  $('#list-view').on('click', function() {
    setView('list');
  });
  
  // Wishlist functionality
  $('.wishlist-btn').on('click', function() {
    const $icon = $(this).find('i');
    if ($icon.hasClass('far')) {
      $icon.removeClass('far').addClass('fas').css('color', '#ef4444');
      showNotification('Added to wishlist!');
    } else {
      $icon.removeClass('fas').addClass('far').css('color', '');
      showNotification('Removed from wishlist!');
    }
  });
  
  // Product card click navigation (excluding buttons)
  $(document).on('click', '.product-card', function(e) {
    // Don't navigate if clicking on buttons or their children
    if ($(e.target).closest('button').length > 0) {
      return;
    }
    
    // Get the product ID and navigate to detail page
    const productId = $(this).data('product-id');
    if (productId) {
      window.location.href = `/products/${productId}`;
    }
  });
  
  // Add to cart button click handler
  $(document).on('click', '.add-to-cart-btn', function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const productId = $(this).data('product-id');
    console.log('Add to cart clicked for product:', productId);
    
    // Get the product's validity price from the product card
    const productCard = $(this).closest('.product-card');
    const priceElement = productCard.find('.text-2xl.font-bold');
    const validityPrice = parseFloat(priceElement.text().replace('₹', '').trim());
    
    console.log('Validity price:', validityPrice);
    
    const cartData = {
      product_id: productId,
      quantity: 1,
      validity: 'days',
      duration: 30,
      price: validityPrice
    };
    
    console.log('Cart data:', cartData);
    
    $.ajax({
      url: '/cart/add_item',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      data: JSON.stringify(cartData),
      success: function(data) {
        console.log('Add to cart success:', data);
        if (data.success) {
          showNotification(data.message);
          updateCartDisplay(data.cart_count, data.cart_total);
          
          // Update header cart count
          updateHeaderCartCount(data.cart_count);
        } else {
          showNotification(data.message, 'error');
        }
      },
      error: function(xhr, status, error) {
        console.error('Add to cart error:', xhr.responseText);
        showNotification('Error adding item to cart', 'error');
      }
    });
  });
}



// Filter products by category
function filterProducts() {
  const category = $('#category-filter').val();
  const $productCards = $('.product-card');
  let visibleCount = 0;
  
  $productCards.each(function() {
    const $card = $(this);
    if (category === 'all' || $card.data('category') === category) {
      $card.show();
      visibleCount++;
    } else {
      $card.hide();
    }
  });
  
  $('#results-count').text(visibleCount);
}

// Sort products
function sortProducts() {
  const sortBy = $('#sort-options').val();
  const $productsGrid = $('#products-grid');
  const $productCards = $('.product-card').toArray();
  
  $productCards.sort(function(a, b) {
    const $a = $(a);
    const $b = $(b);
    
    switch(sortBy) {
      case 'price-low':
        return parseFloat($a.data('price')) - parseFloat($b.data('price'));
      case 'price-high':
        return parseFloat($b.data('price')) - parseFloat($a.data('price'));
      case 'rating':
        return parseFloat($b.data('rating')) - parseFloat($a.data('rating'));
      case 'popularity':
        return $b.data('badge') === 'Popular' ? 1 : -1;
      case 'newest':
        return $b.data('badge') === 'New' ? 1 : -1;
      default:
        return 0;
    }
  });
  
  // Re-append sorted cards
  $productCards.forEach(function(card) {
    $productsGrid.append(card);
  });
}

// Set view mode
function setView(mode) {
  const $gridBtn = $('#grid-view');
  const $listBtn = $('#list-view');
  const $productsGrid = $('#products-grid');
  
  if (mode === 'grid') {
    $productsGrid.removeClass().addClass('grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6');
    $gridBtn.removeClass().addClass('px-3 py-2 bg-indigo-600 text-white hover:bg-indigo-700 transition duration-200');
    $listBtn.removeClass().addClass('px-3 py-2 bg-white text-gray-600 hover:bg-gray-50 transition duration-200');
  } else {
    $productsGrid.removeClass().addClass('space-y-4');
    $listBtn.removeClass().addClass('px-3 py-2 bg-indigo-600 text-white hover:bg-indigo-700 transition duration-200');
    $gridBtn.removeClass().addClass('px-3 py-2 bg-white text-gray-600 hover:bg-gray-50 transition duration-200');
  }
}

// Quick view function
function quickView(productId) {
  showNotification('Quick view feature coming soon!');
}

// View product details
function viewProduct(productId) {
  showNotification('Product detail page coming soon!');
}

// Scroll to products
function scrollToProducts() {
  $('html, body').animate({
    scrollTop: $('#products-grid').offset().top - 100
  }, 800);
}

// Contact sales
function contactSales() {
  window.location.href = '/contact';
}



// Show notification
function showNotification(message, type = 'success') {
  const $notification = $('<div>', {
    class: `fixed top-20 right-4 px-6 py-3 rounded-lg shadow-lg z-50 transform translate-x-full transition-transform duration-300 ${type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}`,
    text: message
  });
  
  $('body').append($notification);
  
  setTimeout(function() {
    $notification.removeClass('translate-x-full');
  }, 100);
  
  setTimeout(function() {
    $notification.addClass('translate-x-full');
    setTimeout(function() {
      $notification.remove();
    }, 300);
  }, 3000);
}

// Update cart display
function updateCartDisplay(count, total) {
  $('#cart-count').text(count);
  $('#cart-total').text(`₹${total}`);
}

// Update header cart count
function updateHeaderCartCount(count) {
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

// Initialize products functionality when DOM is ready
$(document).ready(function() {
  // Only initialize if we're on a page with products
  if ($('.product-card').length > 0 || $('#products-grid').length > 0) {
    initializeProducts();
  }
});
