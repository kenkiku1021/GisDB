require "singleton"
require "tmpdir"
require "yaml"
require "pg"

module GisDBLib
  SRID = 6668
  TARGETS = ["jp_admin_areas"]
  COLUMNS_TABLE = {
    "jp_admin_areas" => [
      ["N03_001", "pref"],
      ["N03_002", "sub_pref"],
      ["N03_003", "major_city"],
      ["N03_004", "city"],
      ["N03_007", "admin_code"],
    ],
  }
  CODEPAGE = {
    "jp_admin_areas" => "cp932",
  }
  
  class Config
    include Singleton

    def initialize
      config_file = "./config.yaml"
      @config = YAML.load(IO.read(config_file))
    end

    def db_conn_string
      host = @config["postgis"]["host"] ? @config["postgis"]["host"] : "localhost"
      port = @config["postgis"]["port"] ? @config["postgis"]["port"] : 5432
      db = @config["postgis"]["db"]
      user = @config["postgis"]["user"]
      password = @config["postgis"]["password"]
      "postgresql://#{user}:#{password}@#{host}:#{port}/#{db}"
    end

    def db_conn
      conn = PG.connect(db_conn_string)
    end
  end

  def self.valid_target?(target)
    TARGETS.include?(target)
  end

  def self.import_shp(target, src_file)
    unless valid_target?(target)
      raise "Invalid target: #{target}"
    end
    unless File.exists?(src_file)
      raise "Src file not exists: #{src_file}"
    end
    
    config = Config.instance
    columns = COLUMNS_TABLE[target]
    codepage = CODEPAGE[target]
    Dir.mktmpdir do |dir|
      map_file = File.join(dir, "map.txt")
      sql_file = File.join(dir, "import.sql")
      File.open(map_file, "w") do |f|
        columns.each {|item| f.print "#{item[1]} #{item[0]}\n"}
      end

      shp2pgsql_cmd = "shp2pgsql -W #{codepage} -D -I -s #{SRID} -m #{map_file} #{src_file} #{target} > #{sql_file}"
      import_cmd = "psql #{config.db_conn_string} -f #{sql_file}"

      exec_cmd shp2pgsql_cmd
      exec_cmd import_cmd
    end
  end

  def self.drop_table(target)
    unless valid_target?(target)
      raise "Invalid target: #{target}"
    end

    config = Config.instance
    conn = config.db_conn
    sql = "DROP TABLE #{target}"
    exec_sql conn, sql
  end

  def self.exec_sql(conn, sql)
    STDERR.print #[sql] #{sql}\n"
    conn.exec sql
  end
  
  def self.exec_cmd(cmd)
    STDERR.print "[exec] #{cmd}\n"
    `#{cmd}`
  end
end
