class StaticPagesController < ApplicationController

  include PatientsHelper

  def home
#    clear_pat_session
    redirect_to current_user.patient if current_user && current_user.patient
#    flash[:info] = "pat #{current_patient.inspect}  user : #{current_user.inspect}"
  end

  def help
  end

  def about
  end

  def contact
  end
  
  def news
  end

  def terms
  end

  def privacy
  end
end
