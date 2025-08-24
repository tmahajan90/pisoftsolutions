class Admin::ContactsController < AdminController
  before_action :set_contact, only: [:show, :update, :destroy]

  def index
    @contacts = Contact.recent.limit(20)
    @new_contacts_count = Contact.unread.count
    @pending_contacts_count = Contact.pending.count
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

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:contact_status)
  end
end
