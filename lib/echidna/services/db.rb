require "sequel"

class DatabaseService
  @DB = nil

  def initialize
    @DB = Sequel.sqlite('youtube.db')
  end

  def db
    @DB
  end

  def run_migrations
    db.create_table? :videos do
      primary_key :id
      String :video_id, unique: true 
      String :channel_title
      DateTime :published_at
    end
  end

  def get_video(video_id)
    video = db[:videos].where(video_id: video_id).first
    if video
      {
        id: video[:id],
        video_id: video[:video_id],
        channel_title: video[:channel_title],
        published_at: video[:published_at].to_datetime,
      }
    else
      nil
    end
  end

  def insert_video(video_id, channel_title, published_at)
    puts "DB: Inserting video #{video_id}"
    db[:videos].insert(video_id: video_id, channel_title: channel_title, published_at: published_at)
  end
end