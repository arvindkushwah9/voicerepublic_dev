#!/usr/bin/env ruby

require 'faraday'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'logger'

log_path = File.join(ENV['HOME'], 'job.log')
LOGGER = Logger.new(log_path)

SLACKLEVELS = [:error, :fatal, :info]

LEVELMAP = {
  debug: Logger::Severity::DEBUG,
  error: Logger::Severity::ERROR,
  fatal: Logger::Severity::FATAL,
  info: Logger::Severity::INFO,
  warn: Logger::Severity::WARN
  # unknown: Logger::Severity::UNKNOWN
}

def log(arg1, arg2)
  level, msg = LEVELMAP.keys.include?(arg1) ? [arg1, arg2] : [:info, arg1]
  LOGGER.log(LEVELMAP[level] || 0, msg)
  msg = '[%s] %s' % [level, msg]
  puts msg
  slack(msg) if SLACKLEVELS.include?(level)
end

# make it autoflush
STDOUT.sync = true

INSTANCE_ENDPOINT = ENV['INSTANCE_ENDPOINT']
QUEUE_ENDPOINT = ENV['QUEUE_ENDPOINT']
INSTANCE = ENV['INSTANCE']
SLACK_CHANNEL = ENV['SLACK_CHANNEL'] || '#simon'

# terminate if there is nothing to do for 6 hours
MAX_WAIT_COUNT = 60 * 6

def faraday
  @faraday ||= Faraday.new(url: QUEUE_ENDPOINT) do |f|
    log :debug, "Setup Faraday with endpoint #{QUEUE_ENDPOINT}"
    uri = URI.parse(QUEUE_ENDPOINT)
    f.basic_auth(uri.user, uri.password)
    f.request :url_encoded
    f.adapter Faraday.default_adapter
  end
end

def die(response)
  warn "It is dead, Jim."
  exit
end

def job_list
  log :debug, "Retrieving job list..."
  response = faraday.get
  while response.status != 200 do
    log :error, "Response Status #{response.status}, endpoint unavailable?"
    log :debug, "Waiting for 10 seconds then retry..."
    sleep 10
    log :debug, "Retrying..."
    response = faraday.get
  end
  JSON.parse(response.body)
end

def terminate
  faraday.put(instance_url, instance: { event: 'terminate' })
  log :info, "`#{INSTANCE}` terminating."
  exit 0
end

def queue_url(job)
  [QUEUE_ENDPOINT, job['id']] * '/'
end

def claim(job)
  log :debug, "Claiming job #{job['id']}..."
  response = faraday.put(queue_url(job), job: {event: 'start', locked_by: INSTANCE})
  response.status == 200
end

def fidelity(path)
  log :debug, "Running fidelity..."
  log :debug, %x[./fidelity/bin/fidelity run #{path}/manifest.yml]
end

def wav2json(path, file)
  log :debug, "Running wav2json..."
  log :debug, %x[./wav2json.sh #{path}/#{file}]
end

# find the first mp3 in path, convert it to wav and return its name
def prepare_wave(path)
  log :debug, "Preparing wave file..."
  wav = nil
  Dir.chdir(path) do
    mp3 = Dir.glob('*.mp3').first
    raise 'no mp3' if mp3.nil?
    wav = mp3.sub('.mp3', '.wav')
    system "sox #{mp3} #{wav}"
  end
  wav
end

def complete(job)
  log :debug, "Marking job #{job['id']} as complete."
  faraday.put(queue_url(job), job: {event: 'complete'})
  log :info, "Marked job #{job['id']} as completed."
end

def s3_cp(source, target, region=nil)
  cmd = "aws s3 cp #{source} #{target}"
  cmd += " --region #{region}" unless region.nil?
  log :debug, cmd
  log :debug, %x[#{cmd}]
end

def s3_sync(source, target, region=nil)
  cmd = "aws s3 sync #{source} #{target}"
  cmd += " --region #{region}" unless region.nil?
  log :debug, cmd
  log :debug, %x[#{cmd}]
end

def probe_duration(path)
  cmd = "ffmpeg -i #{path} 2>&1 | grep Duration"
  output = %x[ #{cmd} ]
  md = output.match(/\d+:\d\d:\d\d/)
  md ? md[0] : nil
end

def metadata(file)
  duration = probe_duration(file)
  result = {
    basename: File.basename(file),
    ext:      File.extname(file),
    size:     File.size(file),
    duration: duration
  }
  # add duration in seconds
  if duration
    h, m, s = duration.split(':').map(&:to_i)
    result[:seconds] = (h * 60 + m) * 60 + s
  end
  result
end

def whatever2ogg(path)
  wav = "#{path}.wav"
  ogg = "#{path}.ogg"

  %x[ ffmpeg -n -loglevel panic -i #{path} #{wav}; \
      oggenc -Q -o #{ogg} #{wav}]

  [wav, ogg]
end

def run(job)
  log :info, "Claimed job #{job['id']} on #{public_ip_address}. Processing..."

  tmp_prefix = "job_#{job['id']}_"

  path = Dir.mktmpdir(tmp_prefix)

  source_bucket = [ 's3:/',
                    job['details']['recording']['bucket'],
                    job['details']['recording']['prefix'] ] * '/'
  target_bucket = [ 's3:/',
                    job['details']['archive']['bucket'],
                    job['details']['archive']['prefix'] ] * '/'

  source_region = job['details']['recording']['region']
  target_region = job['details']['archive']['region']

  type = job['type']

  log :debug, "Working directory: #{path}"
  log :debug, "Source bucket:     #{source_bucket}"
  log :debug, "Target bucket:     #{target_bucket}"
  log :debug, "Job Type:          #{type}"

  # pull manifest file
  manifest_url = "#{target_bucket}/manifest.yml"
  s3_cp(manifest_url, path, target_region)

  case type

  when "Job::Archive"

    # based on content pull source files
    manifest_path = File.join(path, 'manifest.yml')
    raise "No manifest file!" unless File.exist?(manifest_path)
    manifest = YAML.load(File.read(manifest_path))
    manifest[:relevant_files].each do |file|
      s3_url = "#{source_bucket}/#{file.first}"
      s3_cp(s3_url, path, source_region)
    end

  when "Job::ProcessUpload"

    url = job['details']['upload_url']
    log :info, "Upload URL: `#{url}`"

    filename = url.split('/').last.split('?').first
    log :info, "Filename: `#{filename}`"

    if url.match(/^s3:\/\//)
      log :debug, "Copy from S3..."
      s3_cp(url, path, source_region)
    else
      cmd = "cd #{path}; wget -O '#{filename}' --no-check-certificate -q '#{url}'"
      log :debug, cmd
      %x[#{cmd}]
    end

    upload = File.join(path, filename)
    log :info, "Source: `#{upload}`"
    log :info, "Data in "+%x[file #{upload}]

    wav, ogg = whatever2ogg(upload)
    log :debug, "Wav file:          #{wav}"
    log :debug, "Ogg File:          #{ogg}"

    File.unlink(upload)
    File.rename(ogg, "#{path}/override.ogg")

    # TODO the oldschool way of uploading stuff would have set
    # `recording_override` to the s3 url of the ogg file

    manifest_path = File.join(path, 'manifest.yml')
    manifest = YAML.load(File.read(manifest_path))
    name = manifest[:id]

    expected = "#{path}/#{name}.wav"
    log :debug, "Expected wav:      #{expected}"
    File.rename(wav, expected)

  else

    log :fatal, "Unknown job type: `#{type}`, job: `#{job.inspect}`"
    terminate

  end

  # bulk work
  fidelity(path)
  wave = prepare_wave(path)
  wav2json(path, wave)

  # cleanup: delete dump files
  File.unlink(File.join(path, wave))
  manifest[:relevant_files].each do |file|
    dump = File.join(path, file.first)
    File.unlink(dump) if File.exist?(dump)
  end

  # collect index data
  index = {}
  prefix = job['details']['archive']['prefix']
  Dir.glob(File.join(path, '*')).each do |file|
    base = File.basename(file)
    index["#{prefix}/#{base}"] = metadata(file)
  end

  # write index file
  index_yaml = File.join(path, 'index.yml')
  log :debug, "Writing #{index_yaml}"
  File.open(index_yaml, 'w') do |f|
    f.write(YAML.dump(index))
  end

  # upload all files from path to target_bucket
  log :info, "Syncing to #{target_bucket} in region #{target_region}..."
  s3_sync(path, target_bucket+'/', target_region)

  # cleanup: delete everything
  log :debug, "Cleaning up..."
  FileUtils.rm_rf(path)

  # mark job as completed
  complete(job)
end

def wait
  log :debug, 'Sleeping for 1 min. Then poll queue again...'
  sleep 60
end

def instance_url
  [INSTANCE_ENDPOINT, INSTANCE] * '/'
end

def public_ip_address
  faraday.get('http://169.254.169.254/latest/meta-data/public-ipv4').body
rescue
  nil
end

def report_ready
  faraday.put(instance_url, instance:
                              { public_ip_address: public_ip_address,
                                event: 'complete'})
end

def report_failure
  faraday.put(instance_url, instance: { event: 'failed' })
end

def slack(message)
  url = "https://voicerepublic.slack.com/services/hooks/incoming-webhook"+
        "?token=VtybT1KujQ6EKstsIEjfZ4AX"
  payload = {
    channel: SLACK_CHANNEL,
    username: 'AudioWorker',
    text: message,
    icon_emoji: ':cloud:'
  }
  json = JSON.unparse(payload)
  cmd = "curl -X POST --data-urlencode 'payload=#{json}' '#{url}' 2>&1"
  %x[ #{cmd} ]
end

job_count = 0
wait_count = 0

# this is just a test
log :info, "`#{INSTANCE}` up and running on #{public_ip_address}..."

# with a region given this should always work
%x[aws configure set default.s3.signature_version s3v4]

# main
begin
  report_ready
  while true
    jobs = job_list
    if jobs.empty?
      log :debug, "Job list empty."
      if job_count > 0
        terminate
      end
      if wait_count >= MAX_WAIT_COUNT
        log :fatal, "`#{INSTANCE}` terminating after 6 hours idle time. But that's ok."
        terminate
      end
      wait
      wait_count += 1
    else
      job = jobs.first
      if claim(job)
        run(job)
        job_count += 1
        wait_count = 0
      else
        log :error, "Failed to claim job #{job['id']}. Maybe it has been snatched already. Retry in 5s."
        sleep 5
      end
    end
  end
rescue => e
  report_failure
  log :fatal, "Something went wrong: `#{e.message}`"
  terminate
  exit 0
  # NOTE ideally this would not terminate the worker to keep it
  # running for inspection
  #
  # slack "`#{INSTANCE}` on `#{public_ip_address}`" +
  #       " NOT terminating. Action required!"
  # exit 1
  #
  # But since VR is not developed actively anymore, this will result
  # in a lot of orphaned servers running on EC2, so instead we will
  # return exit code 0, to make the server shut down.
end
