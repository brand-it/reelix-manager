class Config::VideosController < ApplicationController
  # @rbs @config_video: Config::Video

  #: () -> void
  def new
    existing = Config::Video.newest
    if existing.persisted?
      redirect_to edit_config_video_path
    else
      @config_video = existing #: Config::Video
    end
  end

  #: () -> void
  def create
    @config_video = Config::Video.new(video_params) #: Config::Video
    if @config_video.save
      redirect_to edit_config_video_path, notice: "Settings saved successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  #: () -> void
  def edit
    @config_video = Config::Video.newest #: Config::Video
    redirect_to new_config_video_path unless @config_video.persisted?
  end

  #: () -> void
  def update
    @config_video = Config::Video.newest #: Config::Video
    if @config_video.persisted?
      if @config_video.update(video_params)
        redirect_to edit_config_video_path, notice: "Settings updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to new_config_video_path
    end
  end

  private

  #: () -> ActionController::Parameters
  def video_params
    params.require(:config_video).permit(:settings_movie_path, :settings_tv_path, :settings_tmdb_api_key, :settings_processed_path)
  end
end
