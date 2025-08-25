document.addEventListener('DOMContentLoaded', function() {
  const selectAllCheckbox = document.getElementById('select-all-products');
  const productCheckboxes = document.querySelectorAll('.product-checkbox');
  const bulkActionsDiv = document.getElementById('bulk-actions');
  const bulkStatusForm = document.getElementById('bulk-status-form');
  const bulkStatusBtn = document.getElementById('bulk-status-btn');
  const newStatusSelect = document.querySelector('select[name="new_status"]');

  if (!selectAllCheckbox || !bulkActionsDiv) return;

  // Handle select all checkbox
  selectAllCheckbox.addEventListener('change', function() {
    productCheckboxes.forEach(checkbox => {
      checkbox.checked = this.checked;
    });
    updateBulkActionsVisibility();
  });

  // Handle individual checkboxes
  productCheckboxes.forEach(checkbox => {
    checkbox.addEventListener('change', function() {
      updateBulkActionsVisibility();
      updateSelectAllCheckbox();
    });
  });

  // Handle new status select change
  if (newStatusSelect) {
    newStatusSelect.addEventListener('change', function() {
      if (bulkStatusBtn) {
        bulkStatusBtn.disabled = !this.value;
      }
    });
  }

  // Update bulk actions visibility
  function updateBulkActionsVisibility() {
    const checkedCount = document.querySelectorAll('.product-checkbox:checked').length;
    if (checkedCount > 0) {
      bulkActionsDiv.style.display = 'block';
    } else {
      bulkActionsDiv.style.display = 'none';
    }
  }

  // Update select all checkbox state
  function updateSelectAllCheckbox() {
    const checkedCount = document.querySelectorAll('.product-checkbox:checked').length;
    const totalCount = productCheckboxes.length;
    
    if (checkedCount === 0) {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    } else if (checkedCount === totalCount) {
      selectAllCheckbox.checked = true;
      selectAllCheckbox.indeterminate = false;
    } else {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = true;
    }
  }

  // Initialize
  updateBulkActionsVisibility();
});
