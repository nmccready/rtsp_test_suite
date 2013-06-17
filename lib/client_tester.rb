#!/usr/bin/env ruby

require 'thor'
require 'rtsp/client'
require 'bundler/setup'

RTSP::Client.log = true

class ClientTester < Thor
  include Thor::Actions

  desc "soma", "Pulls a stream from SomaFM"
  method_options capture_file: :boolean, duration: :numeric
  def soma
    url = "rtsp://64.202.98.91/sa.sdp"
    pull_stream url, options
  end

  desc "sarix", "Pulls a stream from a Sarix camera"
  method_options capture_file: :boolean, duration: :numeric
  def sarix
    url = "rtsp://10.221.222.242/stream1"
    pull_stream url, options
  end

  desc "nsm", "Pulls a stream from a NSM"
  method_options capture_file: :boolean, duration: :numeric
  def nsm
    url = "rtsp://10.221.241.208/?deviceid=uuid:0f4b187e-d6dd-414d-9400-1b0d2ee225a1&starttime=2012-12-06T12:20:25&endtime=2012-12-07T01:39:09"
    pull_stream url, options
  end

  no_tasks do
    def pull_stream(url, options={})
      capture_file = options[:capture_file] || false
      duration = options[:duration] || 5
      client = RTSP::Client.new(url)

      client.options
      client.describe

      media_track = client.media_control_tracks.first
      puts "media track: #{media_track}"

      aggregate_track = client.aggregate_control_track
      puts "aggregate track: #{aggregate_track}"

      client.setup media_track

      if capture_file
        client.play(aggregate_track)
      else
        client.play(aggregate_track) do |packet|
          this_packet = packet.sequence_number
          puts "RTP sequence: #{this_packet}"
          puts "payload type", packet.payload_type

          if defined? last_packet
            puts "last: #{last_packet}"
            diff = this_packet - last_packet
            if diff != 1
              puts "ZOMG!!!!!!!! PACKET DIFF: #{diff}"
            end
          end

          last_packet = packet.sequence_number
        end
      end

      sleep duration
      client.teardown aggregate_track
      puts "Capture file path: #{client.capturer.capture_file.path}"
      puts "Capture file size: #{client.capturer.capture_file.size}"
    end
  end
end

ClientTester.start