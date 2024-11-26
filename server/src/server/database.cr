require "db"
require "sqlite3"
require "uuid"

class Tuba::Database
  def initialize(@database : String = CONFIG.database)
    cleanup # let's clean-up on boot
  end

  def insert(accounts : Array(String), analytics : String)
    DB.open("sqlite3://#{@database}") do |db|
      db.exec "CREATE TABLE IF NOT EXISTS analytics_accounts (id TEXT, analytics_id TEXT, account TEXT, date DATETIME, PRIMARY KEY (id))"
      db.exec "CREATE TABLE IF NOT EXISTS analytics (id TEXT, analytics TEXT, date DATETIME, PRIMARY KEY (id))"

      weeks_passed = true
      accounts_vars = ("?, " * accounts.size)[0..-3]
      db.query("SELECT date, analytics_id FROM analytics_accounts WHERE account IN (#{accounts_vars})", args: accounts) do |rs|
        analytics_ids = [] of String
        rs.each do
          weeks_passed = (Time.utc - Time.parse_utc(rs.read(String), "%F %T.%N")).days >= 14
          break unless weeks_passed # Only continue if a day has passed
          analytics_ids << rs.read(String)
        end

        # Delete analytics that already exist for said accounts.
        # We need to remove both the inputted accounts AND accounts that match the
        # previously found analytics IDs.
        # Users can remove or add new accounts so we need to clear ALL that we find
        # from previous pushes.
        if weeks_passed && analytics_ids.size > 0
          analytics_vars = ("?, " * analytics_ids.size)[0..-3]

          db.exec("DELETE FROM analytics_accounts WHERE account IN (#{accounts_vars}) OR analytics_id IN (#{analytics_vars})", args: accounts + analytics_ids)
          db.exec("DELETE FROM analytics WHERE id IN (#{analytics_vars})", args: analytics_ids)
        end
      end

      # If a day has passed (or it's a new account), insert many at once.
      if weeks_passed
        analytics_id = UUID.random.to_s
        time_now = Time.utc
        analytics_accounts_vars = ("(?, ?, ?, ?), " * accounts.size)[0..-3]

        analytics_accounts_values = [] of String | Time
        accounts.each do |acc_id|
          analytics_accounts_values.push(UUID.random.to_s, analytics_id, acc_id, time_now)
        end

        db.exec "INSERT INTO analytics VALUES (?, ?, ?)", analytics_id, analytics, time_now
        db.exec("INSERT INTO analytics_accounts (id, analytics_id, account, date) VALUES #{analytics_accounts_vars}", args: analytics_accounts_values)
      end
    end
  end

  def clear
    DB.open("sqlite3://#{@database}") do |db|
      db.exec "DROP TABLE IF EXISTS analytics_accounts"
      db.exec "DROP TABLE IF EXISTS analytics"

      db.exec "CREATE TABLE IF NOT EXISTS analytics_accounts (id TEXT, analytics_id TEXT, account TEXT, date DATETIME, PRIMARY KEY (id))"
      db.exec "CREATE TABLE IF NOT EXISTS analytics (id TEXT, analytics TEXT, date DATETIME, PRIMARY KEY (id))"
    end
  end

  # Remove left over analytics and analytics accounts that no longer match any other entry.
  def cleanup
    DB.open("sqlite3://#{@database}") do |db|
      db.exec "CREATE TABLE IF NOT EXISTS analytics_accounts (id TEXT, analytics_id TEXT, account TEXT, date DATETIME, PRIMARY KEY (id))"
      db.exec "CREATE TABLE IF NOT EXISTS analytics (id TEXT, analytics TEXT, date DATETIME, PRIMARY KEY (id))"

      analytics_to_delete = [] of String
      db.query "SELECT id FROM analytics" do |rs|
        rs.each do
          analytics_id = rs.read(String)
          db.query("SELECT 1 FROM analytics_accounts WHERE analytics_id=(?)", analytics_id) do |rs_accounts|
            found = false
            rs_accounts.each do
              found = true
              break
            end

            analytics_to_delete << analytics_id unless found
          end
        end
      end

      analytics_to_delete_vars = ("?, " * analytics_to_delete.size)[0..-3]
      db.exec("DELETE FROM analytics WHERE id IN (#{analytics_to_delete_vars})", args: analytics_to_delete)

      accounts_to_delete = [] of String
      db.query "SELECT analytics_id, id FROM analytics_accounts" do |rs|
        rs.each do
          db.query("SELECT 1 FROM analytics WHERE id=(?)", rs.read(String)) do |rs_analytics|
            found = false
            rs_analytics.each do
              found = true
              break
            end

            accounts_to_delete << rs.read(String) unless found
          end
        end
      end

      accounts_to_delete_vars = ("?, " * accounts_to_delete.size)[0..-3]
      db.exec("DELETE FROM analytics_accounts WHERE id IN (#{accounts_to_delete_vars})", args: accounts_to_delete)
    end
  end
end
