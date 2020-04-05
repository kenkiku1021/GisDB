#!/usr/bin/env ruby
require "./lib/gisdb-lib"

def usage
  STDERR.print <<EOS
Usage:
#{$0} target src_file
  target: jp_admin_area
  src_file: src file (shape file)
EOS
end

if ARGV.length < 2
  usage
  exit 1
end

target = ARGV[0]
src_file = ARGV[1]

begin
  GisDBLib.import_shp target, src_file
rescue => ex
  STDERR.print "[ERROR] #{ex.message}\n"
  ex.backtrace.each {|bt| STDERR.print bt + "\n"}
end
