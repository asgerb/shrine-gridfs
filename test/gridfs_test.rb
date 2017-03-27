require "test_helper"
require "shrine/storage/linter"
require "mongo"
require "logger"

describe Shrine::Storage::Gridfs do
  def gridfs(options = {})
    options[:client] ||= Mongo::Client.new("mongodb://127.0.0.1:27017/mydb", logger: Logger.new(nil))

    Shrine::Storage::Gridfs.new(options)
  end

  before do
    @gridfs = gridfs
  end

  after do
    @gridfs.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(@gridfs).call
  end

  describe "#upload" do
    it "allows multiple files with the same filename" do
      @gridfs.upload(fakeio("file1"), id1 = "foo", shrine_metadata: {"filename" => "file.ext"})
      @gridfs.upload(fakeio("file2"), id2 = "bar", shrine_metadata: {"filename" => "file.ext"})

      assert_equal "file1", @gridfs.open(id1).read
      assert_equal "file2", @gridfs.open(id2).read
    end

    it "saves file in batches" do
      content = "a" * 5*1024*1024 + "b" * 5*1024*1024
      @gridfs.upload(fakeio(content), id = "foo")
      assert_equal content, @gridfs.open(id).read
      assert_equal Digest::MD5.hexdigest(content), @gridfs.bucket.files_collection.find(_id: BSON::ObjectId(id)).first[:md5]
    end
  end
end
