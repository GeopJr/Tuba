require "./spec_helper"

describe Tuba::Database do
  before_each do
    DATABASE.clear
  end

  Spec.after_suite do
    File.delete(CONFIG.database)
  end

  it "clears the whole database" do
    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.exec "CREATE TABLE IF NOT EXISTS analytics_accounts (id TEXT, analytics_id TEXT, account TEXT, date DATETIME, PRIMARY KEY (id))"
      db.exec "CREATE TABLE IF NOT EXISTS analytics (id TEXT, analytics TEXT, date DATETIME, PRIMARY KEY (id))"

      db.exec "INSERT INTO analytics_accounts VALUES (?, ?, ?, ?)", "1", "2", "3", Time.utc
      db.exec "INSERT INTO analytics VALUES (?, ?, ?)", "1", "2", Time.utc
    end

    DATABASE.clear

    is_empty = false
    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.query "SELECT 1 FROM analytics" do |rs|
        is_empty = true # query may fail so pretend it's true if successful
        rs.each do
          is_empty = false
          break
        end
      end

      next unless is_empty
      db.query "SELECT 1 FROM analytics_accounts" do |rs|
        is_empty = true # may fail, pretend it's true if successful
        rs.each do
          is_empty = false
          break
        end
      end
    end

    is_empty.should be_true
  end

  it "inserts new analytics" do
    DATABASE.insert(["1", "2"], "3")

    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.query "SELECT analytics_id FROM analytics_accounts WHERE account IN (?, ?)", "1", "2" do |rs|
        is_empty = true
        rs.each do
          is_empty = false

          db.query "SELECT analytics FROM analytics WHERE id=(?)", rs.read(String) do |rs_analytics|
            is_analytics_empty = true

            rs_analytics.each do
              is_analytics_empty = false

              rs_analytics.read(String).should eq("3")
            end

            is_analytics_empty.should be_false
          end
        end

        is_empty.should be_false
      end
    end
  end

  it "doesn't insert new analytics if less than a day has passed" do
    DATABASE.insert(["1", "2"], "3")
    DATABASE.insert(["1", "2"], "4")

    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.query "SELECT analytics_id FROM analytics_accounts WHERE account IN (?, ?)", "1", "2" do |rs|
        is_empty = true
        rs.each do
          is_empty = false

          db.query "SELECT analytics FROM analytics WHERE id=(?)", rs.read(String) do |rs_analytics|
            is_analytics_empty = true

            rs_analytics.each do
              is_analytics_empty = false

              rs_analytics.read(String).should eq("3")
            end

            is_analytics_empty.should be_false
          end
        end

        is_empty.should be_false
      end
    end
  end

  it "overwrites analytics if more than a day has passed" do
    DB.open("sqlite3://#{CONFIG.database}") do |db|
      past_time = Time.utc - Time::Span.new(days: 1)
      db.exec "INSERT INTO analytics_accounts VALUES (?, ?, ?, ?)", "123", "1312", "1", past_time
      db.exec "INSERT INTO analytics VALUES (?, ?, ?)", "1312", "3", past_time
    end
    DATABASE.insert(["1", "2"], "4")

    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.query "SELECT analytics_id FROM analytics_accounts WHERE account IN (?, ?)", "1", "2" do |rs|
        is_empty = true
        rs.each do
          is_empty = false

          db.query "SELECT analytics FROM analytics WHERE id=(?)", rs.read(String) do |rs_analytics|
            is_analytics_empty = true

            rs_analytics.each do
              is_analytics_empty = false

              rs_analytics.read(String).should eq("4")
            end

            is_analytics_empty.should be_false
          end
        end

        is_empty.should be_false
      end
    end
  end

  it "cleans up leftovers" do
    DATABASE.insert(["1", "2"], "3")

    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.exec "INSERT INTO analytics_accounts VALUES (?, ?, ?, ?)", "111", "222", "4", Time.utc
      db.exec "INSERT INTO analytics VALUES (?, ?, ?)", "333", "3", Time.utc
    end

    DATABASE.cleanup

    DB.open("sqlite3://#{CONFIG.database}") do |db|
      db.query "SELECT 1 FROM analytics WHERE id=(?)", "333" do |rs|
        is_empty = true
        rs.each do
          is_empty = false
          break
        end
        is_empty.should be_true
      end

      db.query "SELECT 1 FROM analytics_accounts WHERE id=(?)", "111" do |rs|
        is_empty = true
        rs.each do
          is_empty = false
          break
        end
        is_empty.should be_true
      end

      db.query "SELECT 1 FROM analytics_accounts WHERE account=(?)", "1" do |rs|
        is_empty = true
        rs.each do
          is_empty = false
          break
        end
        is_empty.should be_false
      end
    end
  end
end
