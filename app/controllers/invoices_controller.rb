class InvoicesController < ApplicationController
  include My::Forms

  before_action :set_invoice, only: [:show, :edit, :update, :download, :export, :destroy]
  helper_method :sort_column, :sort_direction
  before_action :logged_in_user, :non_patient_user
# before_action :admin_user, only: :destroy

  def index
    @patient = Patient.find(params[:patient_id]) rescue nil
    if current_user.doctor?
      @invoices = Invoice.where(doctor_id: current_doctor.id)
    elsif @patient.present?
      @invoices = @patient.invoices
    else
      @invoices = Invoice.all
    end
    @invoices = @invoices.reorder(sort_column + ' ' + sort_direction).paginate(page: params[:page])
  end

# We call this always from patient
  def new
    @patient = Patient.find(params[:patient_id])
    @invoice = @patient.invoices.new
  end

  def create
    @patient = Patient.find(params[:patient_id])
    @invoice = @patient.invoices.build(invoice_params)
    @invoice.paid = false
    if @invoice.save
       @invoice.update_attribute(:filename, "inv_#{@invoice.id}.pdf")
       pdf = build_invoice( @invoice )
       pdf.render_file @invoice.filespec
       flash[:success] =  "Invoice ##{@invoice.id} created"
       redirect_to @patient
    else
       flash[:danger] =  "Error creating invoice"
       render 'new'
    end
  end

  def show
   respond_to do |format|
      format.html {
        send_file(@invoice.filespec,
             type: "application/pdf",
             disposition: :inline)        
      }
      format.js
    end
  end

  def download
    if @invoice.present? && File.exists?(@invoice.filespec)
      send_file @invoice.filespec,
             filename: @invoice.filename,
             type: "application/pdf",
             disposition: :attachment
    else
      flash.now[:danger] = "File #{@invoice.filename} was not found - regenerating"
      redirect_to export_invoice_path(@invoice)
    end
  end

# Generate PDF file for the invoice, save in invoices directory
  def export
    @invoice = Invoice.find(params[:id])
    @pdf = build_invoice( @invoice )
    @pdf.render_file @invoice.filespec
    redirect_to @patient, alert: "PDF invoice generated for patient #{@patient.full_name}"
  end

  def edit
  end

  def update
    if @invoice.update(invoice_params)
      pdf = build_invoice( @invoice )
      pdf.render_file @invoice.filespec	    
	    
      flash[:success] = "Invoice updated"
      redirect_to @patient
    else
      render 'edit'
    end
  end

  def destroy
    if @invoice.present?
      File.delete( @invoice.filespec ) rescue nil
      @invoice.destroy
      flash[:success] = "Invoice deleted"
    end
    redirect_to @patient
  end


private
  def invoice_params
          params.require(:invoice).permit(:patient_id, :billto, :visit_id, :amount, :date, :notes, :amount, :paid, :filename, :doctor_id )
  end

  def sort_column
          Invoice.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end

  def sort_direction
          %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  def set_invoice
      @invoice = Invoice.find(params[:id])
      @patient = @invoice.patient

  end

end
