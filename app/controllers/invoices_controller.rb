class InvoicesController < ApplicationController
	include My::Forms

	helper_method :sort_column, :sort_direction

        before_action :logged_in_user 
        before_action :admin_user, only: :destroy

  def index
      @invoices = Invoice.reorder(sort_column + ' ' + sort_direction).paginate(page: params[:page], per_page: $per_page)
      flash.now[:info] = "Showing All Invoices (#{@invoices.count})"
  end

# We call this always from patient
  def new
    @invoice = Invoice.new
    @patient = Patient.find(params[:patient_id])
  end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.date = Date.today
    @invoice.filespec = Rails.root.join(INVOICES_PATH,"inv_#{@invoice.id}.pdf")
    if @invoice.save
       pdf = build_invoice( @invoice )
       pdf.render_file @invoice.filespec
       redirect_to invoices_path
    else
       render 'new'
    end
  end

  def show
   @invoice = Invoice.find( params[:id] )
   redirect_to invoices_path unless @invoice

   respond_to do |format|
      format.html {
        send_file(@invoice.filespec,
             type: "application/pdf",
             disposition: :inline) rescue 'Invoice file is missing'
      }
      format.js
    end
  end

  def edit
    @invoice = Invoice.find( params[:id] )
    @patient = Patient.find( @invoice.patient_id ) rescue Patient.new()
  end

  def update
    @invoice = Invoice.find( params[:id] )
    @patient = Patient.find( @invoice.patient_id ) 

    if @invoice.update_attributes(invoice_params)
      pdf = build_invoice( @invoice )
      pdf.render_file @invoice.filespec	    
	    
      flash[:success] = "Invoice updated"
      redirect_to invoices_path
    else
      render 'edit'
    end
  end

  def destroy
    @invoice = Invoice.find( params[:id] )
    if @invoice.present?
      File.delete( @invoice.filespec ) rescue nil
      @invoice.destroy
      flash[:success] = "Invoice deleted"
    end
    redirect_to invoices_url
  end


private
  def invoice_params
          params.require(:invoice).permit(:patient_id, :billto, :visit_id, :amount, :date, :notes, :amount, :paid, :filespec, :doctor_id )
  end

  def sort_column
          Invoice.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end

  def sort_direction
          %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

end
