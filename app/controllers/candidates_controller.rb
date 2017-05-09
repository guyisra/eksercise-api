class CandidatesController < ApplicationController
  http_basic_authenticate_with name: 'klarna', password: 'do_no_evil'

  def create
    Candidate.create(allowed_params.merge(key: SecureRandom.uuid))

    redirect_to :back
  end

  def index
    @candidates = Candidate.not_expired

    @candidates = @candidates.where('name ILIKE ?', "%#{params[:name]}%") if params[:name]

    @candidates = @candidates.order(:created_at)

    respond_to do |format|
      format.json { render json: @candidates }
      format.html {}
    end
  end

  def evil
    attr = params[:attr]
    return render :bad_request unless Candidate.attribute_names.include?(attr)

    candidate = Candidate.find(params[:id])
    candidate.send("#{attr}=", !candidate.send(attr))
    candidate.save

    redirect_to :back
  end

  private

  def allowed_params
    params.require(:candidate).permit(:name)
  end
end
