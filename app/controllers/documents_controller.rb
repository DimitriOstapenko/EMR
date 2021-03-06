class DocumentsController < ApplicationController

  def new
   @document = Document.new(:visit_id => params[:visit_id])
  end 
	
  def create
   @visit = Visit.find(params[:visit_id])
   @document = @visit.documents.build(document_params)
   if @document.save
#    render :show, status: :created, location: @document
     render json: @document
   else
     render json: @document.errors, status: :unprocessable_entity
   end
 end

private

 def document_params
   params.require(:document).permit(:name, :description, :document, :document_data => []) #add document_data as a permitted parameter
 end

end
