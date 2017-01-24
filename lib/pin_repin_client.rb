require_relative "curb_dsl"
require 'json'
module Pin
  class Client
    Login_URL = "https://www.pinterest.com/resource/UserSessionResource/create/"
    Repin_URL = "https://www.pinterest.com/resource/RepinResource/create/"
    Regex = {
      pin_validation:  /^https?:\/\/www\.pinterest\.com\/pin\/(\d+)/,
      description: /<meta\s+property=\"og:description\"\s+name=\"og:description\"\s+content=\"(.*?)\"\s+data-app>/,
      link: /<meta\s+property=\"og:description\"\s+name=\"og:description\"\s+content=\"(.*?)\"\s+data-app>/
    }
    Pin_Validation_Regex =
    include Curb_DSL
    class << self
      def login(username_or_email, password)
        self.new do
          set_uri Login_URL
          header 'Accept', 'application/json, text/javascript, */*; q=0.01'
          header 'Accept-Language', 'en-US,en;q=0.5'
          header 'Cache-Control', 'no-cache'
          header 'DNT','1'
          header  'Host', 'www.pinterest.com'
          header 'Origin', 'https://www.pinterest.com'
          header 'Referer', 'https://www.pinterest.com/'
          header 'User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'
          header 'Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8'
          header 'X-APP-VERSION', '18733c1'
          header 'X-CSRFToken', 'K4C0QUu35Eoq1xjajbMluw7hOKibpQSW'
          header 'X-NEW-APP', '1'
          header 'X-Pinterest-AppState', 'active'
          header 'X-Requested-With', 'XMLHttpRequest'
          set_cookies({ ":_auth" => '0',csrftoken: 'K4C0QUu35Eoq1xjajbMluw7hOKibpQSW'})

          set_payload({
            source_url: "/login/",
            data: {
              options: {
                username_or_email: username_or_email,
                password: password
              },
              context: {}
          }.to_json,
            module_path: "App()>LoginPage()>Login()>Button(class_name=primary, text=Log In, type=submit, size=large)"
          })
          set_type_converter -> (payload) {query_params(payload)}
          set_error_handler -> {
            JSON.parse(body)['resource_response']['error'].to_s
          }
          post
          @login_cookies = response_cookies
        end
      end
    end

    def repin(board_id,pin_url)
      pin(board_id,pin_url)
    end

    def repin_multi(*args)
      case true
      when args.first.is_a?(String)
        args.last.each_with_object(args.shift).map do |pin_url,board_id|
          pin board_id,pin_url
        end
      when args.first.is_a?(Array)
        args.first.map do |board_id,pin_url|
          pin board_id,pin_url
        end
      else
        args.first.each_with_object({}) do |(board_id,pin_urls),ids|
         ids[board_id] = pin_urls.map do |pin_url|
            ipin board_id,pin_url
          end
        end
      end
      false
    end

    def pin(board_id,pin_url)
      raise 'pin_url is not in the form of https://www.pinterest.com/pin/<pin_id>' unless Regex[:pin_validation] =~ pin_url
      pin_id = $1
      set_uri pin_url
      get
      header 'X-CSRFToken', @login_cookies['csrftoken']
      header 'Referer', pin_url

      set_cookies(@login_cookies)
      set_payload({
        source_url: ("/pin/%s/" % pin_id),
        data: {
          options: {
            # is_buyable_pin: false,
            description: decode_html(Regex[:description] =~ body ? $1 : ''),
            link: (Regex[:link] =~ body ? $1 : ''),
            is_video: false,
            board_id: board_id,
            pin_id: pin_id
          },
          context: {}
        }.to_json,
        module_path: 'App>ModalManager>Modal>PinCreate>PinCreateBoardPicker>BoardPicker>SelectList(view_type=pinCreate, selected_section_index=undefined, selected_item_index=undefined, highlight_matched_text=true, suppress_hover_events=undefined, scroll_selected_item_into_view=true, select_first_item_after_update=false, item_module=[object Object])'
      })
      set_uri Repin_URL
      post
      JSON.parse(body)['resource_response']['data']['id']
    end
  end
end
