class Admin::ContactsController < AdminController
  before_action :set_contact, only: [:show, :update, :destroy]

  def index
    base_query = Contact.all

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.where(
        "contacts.name ILIKE ? OR contacts.email ILIKE ? OR contacts.phone ILIKE ? OR contacts.message ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # Status filter
    if params[:status].present? && Contact.contact_statuses.key?(params[:status])
      base_query = base_query.where(contact_status: params[:status])
    end

    # Requirement filter
    if params[:requirement].present?
      base_query = base_query.where(requirement: params[:requirement])
    end

    # Date range filter
    if params[:date_from].present?
      base_query = base_query.where('contacts.created_at >= ?', Date.parse(params[:date_from]).beginning_of_day)
    end

    if params[:date_to].present?
      base_query = base_query.where('contacts.created_at <= ?', Date.parse(params[:date_to]).end_of_day)
    end

    # Pagination
    @contacts = base_query.recent.limit(25)

    # Statistics
    @total_contacts = Contact.count
    @new_contacts_count = Contact.unread.count
    @pending_contacts_count = Contact.pending.count
    @responded_contacts_count = Contact.responded.count
    @closed_contacts_count = Contact.closed.count

    # Filter counts
    @filtered_count = base_query.count

    # Available requirements for filter dropdown
    @available_requirements = Contact.distinct.pluck(:requirement).compact.sort
  end

  def show
  end

  def update
    if @contact.update(contact_params)
      redirect_to admin_contact_path(@contact), notice: 'Contact status updated successfully.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to admin_contacts_path, notice: 'Contact deleted successfully.'
  end

  def bulk_update
    contact_ids = params[:contact_ids]
    new_status = params[:new_status]

    if contact_ids.present? && new_status.present? && Contact.contact_statuses.key?(new_status)
      Contact.where(id: contact_ids).update_all(contact_status: new_status)
      redirect_to admin_contacts_path, notice: "Updated #{contact_ids.count} contacts to #{new_status.titleize} status."
    else
      redirect_to admin_contacts_path, alert: 'Please select contacts and a valid status.'
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:contact_status)
  end
end
