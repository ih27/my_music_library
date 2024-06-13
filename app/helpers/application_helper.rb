module ApplicationHelper
  def format_time(seconds)
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    format("%d:%02d", minutes, remaining_seconds)
  end

  def total_tracks_count
    Track.count
  end

  def sort_direction(column)
    if params[:sort] == column
      params[:direction] == "asc" ? "desc" : "asc"
    else
      "asc"
    end
  end

  def sort_icon(column)
    if params[:sort] == column
      params[:direction] == "asc" ? "↑" : "↓"
    else
      ""
    end
  end
end
