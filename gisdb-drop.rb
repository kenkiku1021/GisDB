#!/usr/bin/env ruby
require "./lib/gisdb-lib"

def usage
  STDERR.print <<EOS
Usage:
#{$0} target
  target: jp_admin_area
EOS
end

if ARGV.length < 1
  usage
  exit 1
end

target = ARGV[0]

begin
  GisDBLib.drop_table target
rescue => ex
  STDERR.print "[ERROR] #{ex.message}\n"
  ex.backtrace.each {|bt| STDERR.print bt + "\n"}
end
