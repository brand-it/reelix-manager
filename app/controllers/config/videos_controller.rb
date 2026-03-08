class Config::VideosController < ApplicationController
  def new
    @config_video = Config::Video.new
  end

  def create
    @config_video = Config::Video.new(video_params)
    if @config_video.save
      redirect_to edit_config_video_path, notice: "Settings saved successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @config_video = Config::Video.newest
    redirect_to new_config_video_path unless @config_video.persisted?
  end

  def update
    @config_video = Config::Video.newest
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

  def video_params
    params.require(:config_video).permit(:settings_movie_path, :settings_tv_path, :settings_tmdb_api_key, :settings_processed_path)
  end
end
