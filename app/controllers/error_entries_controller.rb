# frozen_string_literal: true

class ErrorEntriesController < ApplicationController
  # Instance variable type declarations for Steep
  # @rbs @error_classes: Array[::String]
  # @rbs @statuses: Array[::Symbol]
  # @rbs @error_entries: ::ActiveRecord::Relation[::ErrorEntry]
  # @rbs @counts_by_status: ::Hash[::Symbol, ::Integer]
  # @rbs @error_entry: ::ErrorEntry
  # @rbs @similar_errors: ::ActiveRecord::Relation[::ErrorEntry]
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_error_entry, only: %i[show acknowledge resolve]

  #: -> void
  def index
    @error_classes = ErrorEntry.unique_error_classes
    @statuses = ErrorEntry.statuses.keys

    # Initialize with all errors
    @error_entries = ErrorEntry.all

    # Filter by error_class
    if params[:error_class].present?
      @error_entries = @error_entries.by_error_class(params[:error_class])
    end

    # Filter by status
    if params[:status].present?
      @error_entries = @error_entries.by_status(params[:status])
    end

    # Get latest error from each fingerprint group
    @error_entries = @error_entries
      .distinct_on_fingerprint
      .recent_first
      .limit(100)

    @counts_by_status = ErrorEntry.counts_by_status
  end

  #: -> void
  def show
    # Show all errors with the same fingerprint
    @similar_errors = ErrorEntry.by_fingerprint(@error_entry.fingerprint)
      .recent_first
      .limit(50)
  end

  #: -> void
  def acknowledge
    @error_entry.update!(status: :acknowledged)
    redirect_to error_entries_path, notice: "Error acknowledged."
  end

  #: -> void
  def resolve
    @error_entry.update!(status: :resolved)
    redirect_to error_entries_path, notice: "Error resolved."
  end

  private

  #: -> void
  def require_admin
    redirect_to root_path unless current_user.admin?
  end

  #: -> void
  def set_error_entry
    @error_entry = ErrorEntry.find(params[:id])
  end
end
