module PlaylistsHelper
  def format_time(seconds)
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    format("%d:%02d", minutes, remaining_seconds)
  end
end
