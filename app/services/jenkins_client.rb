require 'jenkins_api_client'

class JenkinsClient

  def initialize(url, opts = {})
    @url = url

    @options = {}
    @options[:server_url] = @url
    @options[:http_open_timeout] = opts[:http_open_timeout] || 5
    @options[:http_read_timeout] = opts[:http_read_timeout] || 60
    @options[:username] = opts[:username] if opts.has_key?(:username)
    @options[:password] = opts[:password] if opts.has_key?(:password)
  end


  def connection
    JenkinsApi::Client.new(@options)
  rescue ArgumentError => e
    raise RedmineJenkins::Error::JenkinsConnectionError, e
  end


  def test_connection
    test = {}
    test[:errors] = []

    begin
      test[:jobs_count] = get_available_jobs.size
    rescue => e
      test[:jobs_count] = 0
      test[:errors] << e.message
    end

    begin
      test[:version] = connection.get_jenkins_version
    rescue => e
      test[:version] = 0
      test[:errors] << e.message
    end

    return test
  end


  def get_jobs_list
    connection.job.list_all rescue []
  end


  def number_of_builds_for(job_name)
    connection.job.list_details(job_name)['builds'].size rescue 0
  end

  def get_available_jobs
    filter_job_names(search_in_depth).sort
  end


  def filter_job_names(list)
    names = []
    list.each { |item|
      if item.key?("jobs")
        filter_job_names(item["jobs"]).map { |child| 
          names << item["name"] + "/job/" + child
        }
      else
        names << item["name"]
      end
    }
    return names
  end


  def search_in_depth
    connection.api_get_request("", "tree=jobs[name,jobs[name,jobs[name]]]")["jobs"]
  end

end
