document.addEventListener('DOMContentLoaded', function() {
  const selectAllCheckbox = document.getElementById('select-all');
  const contactCheckboxes = document.querySelectorAll('.contact-checkbox');
  const bulkActionsDiv = document.getElementById('bulk-actions');
  const bulkUpdateBtn = document.getElementById('bulk-update-btn');
  const bulkUpdateForm = document.getElementById('bulk-update-form');

  // Handle select all checkbox
  if (selectAllCheckbox) {
    selectAllCheckbox.addEventListener('change', function() {
      contactCheckboxes.forEach(checkbox => {
        checkbox.checked = this.checked;
      });
      updateBulkActionsVisibility();
    });
  }

  // Handle individual checkboxes
  contactCheckboxes.forEach(checkbox => {
    checkbox.addEventListener('change', function() {
      updateBulkActionsVisibility();
      updateSelectAllCheckbox();
    });
  });

  // Update bulk actions visibility
  function updateBulkActionsVisibility() {
    const checkedBoxes = document.querySelectorAll('.contact-checkbox:checked');
    if (checkedBoxes.length > 0) {
      bulkActionsDiv.style.display = 'block';
      bulkUpdateBtn.disabled = false;
    } else {
      bulkActionsDiv.style.display = 'none';
      bulkUpdateBtn.disabled = true;
    }
  }

  // Update select all checkbox state
  function updateSelectAllCheckbox() {
    const checkedBoxes = document.querySelectorAll('.contact-checkbox:checked');
    const totalBoxes = contactCheckboxes.length;
    
    if (checkedBoxes.length === 0) {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    } else if (checkedBoxes.length === totalBoxes) {
      selectAllCheckbox.checked = true;
      selectAllCheckbox.indeterminate = false;
    } else {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = true;
    }
  }

  // Handle bulk update form submission
  if (bulkUpdateForm) {
    bulkUpdateForm.addEventListener('submit', function(e) {
      const checkedBoxes = document.querySelectorAll('.contact-checkbox:checked');
      const newStatus = document.querySelector('select[name="new_status"]').value;
      
      if (checkedBoxes.length === 0) {
        e.preventDefault();
        alert('Please select at least one contact to update.');
        return;
      }
      
      if (!newStatus) {
        e.preventDefault();
        alert('Please select a new status.');
        return;
      }
      
      if (!confirm(`Are you sure you want to update ${checkedBoxes.length} contact(s) to "${newStatus}" status?`)) {
        e.preventDefault();
        return;
      }
    });
  }
});
