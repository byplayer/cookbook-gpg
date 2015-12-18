require 'open-uri'

module BswTech
  module Hkp
    class KeyFetcher
      def fetch_key(key_server, key_id)
        parsed = URI.parse key_server
        url_with_port = parsed.scheme ? key_server : "http://#{key_server}"
        full_url = "#{url_with_port}/pks/lookup?options=mr&op=get&search=0x#{URI.escape key_id}"
        # retry 10 times, because http isn't stable
        max_retry = 50
        try_count = 0
        begin
          open(full_url) do |f|
            raw = f.read
            match = /(-----BEGIN PGP PUBLIC KEY BLOCK-----.*-----END PGP PUBLIC KEY BLOCK-----)/m.match raw
            match[0]
          end
        rescue OpenURI::HTTPError => e
          if try_count <= max_retry
            try_count += 1
            Chef::Log.logger.info "key server return error. retry(#{try_count})"
            sleep 1
            retry
          end
          raise "Contacted key server OK, but key ID '#{key_id}' was not found: #{e}"
        rescue SocketError => e
          raise "Unable to contact key server '#{full_url}', details: #{e}"
        end
      end
    end
  end
end
