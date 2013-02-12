# GET /bio?name=Nikola+Tesla

class BioController < ApplicationController
  ENDPOINT = 'http://en.wikipedia.org/w/api.php'
  BASE_URL = 'http://en.wikipedia.org/wiki'

  def fetch
    res = {}

    if params[:name]
      options = {
        :titles          => params[:name],
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

            # Try to get the page
            page = json['query'].try(:[], 'pages').try(:shift).try(:pop)

            if page
              # Ensure the image is 80px wide
              url = BASE_URL + '/' + page['title'].try(:sub, /\s/, '_')
              image = page['thumbnail'].try(:[], 'source').try(:sub, /\/(\d)+(px)\-/, '/80px-')

              res = {
                :name    => page['title'],
                :url     => url,
                :image   => image,
                :excerpt => page['extract']
              }
            end
          rescue JSON::ParserError => e
            logger.error "Could not parse the response body: #{e}"
          end
        end
      end
    end

    render :json => res
  end
end
