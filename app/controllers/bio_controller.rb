# GET /bio?q=Nikola+Tesla

class BioController < ApplicationController
  ENDPOINT = 'http://en.wikipedia.org/w/api.php'
  BASE_URL = 'http://en.wikipedia.org/wiki'

  def fetch
    render_error('The "q" parameter is required.') && return unless params[:q]
    res = {}

    options = {
      :titles          => params[:q],
      :action          => 'query',
      :format          => 'json',
      :redirects       => true,                  # Automatically resolve redirects
      :prop            => 'pageimages|extracts', # Return main image and excerpt
      :piprop          => 'thumbnail',           # Image thumbnail
      :pithumbsize     => 80,                    # Thumbnail width
      :exintro         => true,                  # Excerpt: Return only content before the first section
      :exsectionformat => 'plain',               # Excerpt: No formatting
      :exsentences     => 2                      # Excerpt: How many sentences to return
    }

    Curl::Easy.perform("#{ENDPOINT}?#{options.to_query}") do |curl|
      curl.headers['User-Agent'] = 'youhadmail-0.0'

      curl.on_body do |body|
        begin
          json = JSON.parse(body)
          logger.info("  \033[0;36mWikipedia Response: \033[0;00m#{json}")

          # Try to get the page
          page = json['query'].try(:[], 'pages').try(:shift).try(:pop)

          if page
            # Replace whitespace in the title with underscores
            url = BASE_URL + '/' + page['title'].try(:gsub, /\s/, '_')

            # Ensure the image is 80px wide
            image = page['thumbnail'].try(:[], 'source').try(:sub, /\/(\d)+(px)\-/, '/80px-')

            # Remove first parenthesis (phonetic spelling)
            excerpt = page['extract'].try(:sub, /\(.+\)\s/, '')

            res = {
              :name    => page['title'],
              :url     => url,
              :image   => image,
              :excerpt => excerpt
            }
          end
        rescue JSON::ParserError => e
          logger.error("Could not parse the response body: #{e}")
          render_error("Could not parse the response body. Check the error log.") && return
        end
      end
    end

    render :json => res
  end

  private
    def render_error(message)
      render :json => { :error => message }
    end
end
