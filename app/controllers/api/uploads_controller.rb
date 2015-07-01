class Api::UploadsController < Api::BaseController
  skip_before_action :verify_authenticity_token, if: lambda { request.format.json? }

  # POST api/uploads
  def create
    @talk = Talk.new(talk_params)
    @talk.venue_user = current_user

    authorize! :create, @talk

    if @talk.save
      render json: @talk.to_json
    else
      render json: { errors: @talk.errors }, status: 422
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def talk_params
    params.require(:talk).permit(:title, :teaser, :starts_at_date,
                                 :starts_at_time,
                                 :description, :image,
                                 :tag_list, :language,
                                 :new_venue_title, :venue_id,
                                 :user_override_uuid)
  end

end