require_relative "curb_dsl"
require 'json'
require 'nokogiri'
module Pin
  class Client
    attr_reader :username, :login_cookies, :sub
    URLs = {
      login: "https://www.pinterest.com/resource/UserSessionResource/create/",
      repin: "https://www.pinterest.com/resource/RepinResource/create/",
      get_boards: "https://www.pinterest.com/resource/BoardPickerBoardsResource/get/",
      create_board: "https://uk.pinterest.com/resource/BoardResource/create/",
      get_pins: "http://pinterestapi.co.uk/%s/pins?page=%s",
      get_pin: "https://www.pinterest.com/resource/PinResource/get",
      get_recent_pins: "https://www.pinterest.com/%s/%s.rss",
      follow_user: "https://www.pinterest.com/resource/UserFollowResource/create/",
      unfollow_user: "https://pinterest.com/resource/UserFollowResource/delete/",
      follow_board: 'https://pinterest.com/resource/BoardFollowResource/create/',
      unfollow_board: 'https://pinterest.com/resource/BoardFollowResource/delete/',
      followers: "https://pinterest.com/resource/UserFollowersResource/get?"
    }
    Regex = {
      pin_validation:  /^https?:\/\/www\.pinterest\.com\/pin\/(\d+)/,
      description: /<meta\s+property=\"og:description\"\s+name=\"og:description\"\s+content=\"(.*?)\"\s+data-app>/,
      link: /<meta\s+property=\"og:description\"\s+name=\"og:description\"\s+content=\"(.*?)\"\s+data-app>/
    }
    Pin_Validation_Regex =
    include Curb_DSL
    class << self
      def login(username_or_email, password,sub=false)
        self.new do
          set_uri subdomain(URLs[:login])

          set_cookies({ ":_auth" => '0',csrftoken: 'K4C0QUu35Eoq1xjajbMluw7hOKibpQSW'})

          set_payload({
            source_url: "/login/",
            module_path: "App()>LoginPage()>Login()>Button(class_name=primary, text=Log In, type=submit, size=large)",
            data: data_json({
              username_or_email: username_or_email,
              password: password
            })
          })
          post
          @sub = sub
          @username = username_or_email
          @login_cookies = response_cookies
        end
      end
    end

    def initialize(username_or_email="",login_cookies={},&block)
      @username = username_or_email
      @login_cookies = login_cookies
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
      set_type_converter -> (payload) {query_params(payload)}
      set_error_handler -> {
        JSON.parse(body)['resource_response']['error'].to_s
      }
      super(&block) if block_given?
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

    def get_pin(pin_id)
      set_uri subdomain(URLs[:get_pin])
      set_cookies @login_cookies
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_payload({
        source_url: "/pin/%s/" % pin_id,
        module_path: "App>HomePage>AuthHomePageWrapper>AuthHomePage>Grid>GridItems>Pin(show_tenzing_like=true, show_pinner=true, component_type=0, show_feedback_tool=true, hide_comments_pfy_interests=true, show_board=true, insert_on_trigger=true, use_native_image_width=true, dynamic_insertion_channel=homefeed, is_homefeed_pin_credits=true, show_reason=true, in_image_only_hf=false, show_pinned_from=false, show_more_ring=false, resource=PinResource(main_module_name=null, id=%s))" % pin_id,
        data: data_json({
          id: pin_id,
          field_set_key: "detailed",
          ptrf: "null",
          fetch_visual_search_objects: "true",
          allow_stale: true
        })
      })
      post
      JSON.parse(body)['resource_response']['data']
    end

    def get_recent_pins(board_name,username=@username)
      set_cookies @login_cookies
      set_uri subdomdawain(URLs[:get_recent_pins] % [username,board_name])
      ignore_error
      get
      case status_code
      when 200
        Nokogiri::HTML(body).xpath('//rss//channel//item').map do |item|
          {
            title:        item.xpath('.//title').text,
            link:         item.xpath('.//link').text,
            description:  item.xpath('.//description').text,
            pubDate:      item.xpath('.//pubdate').text,
            guid:         item.xpath('.//guid').text
          }

        end
      when 404
        false
      end
    end

    # def get_pins(board_id)
    # keep_going = true
    # page = 0
    # results = []
      # while keep_going
      #   set_uri subdomain(URLs[:get_pins]  % [@username,page])
      #   get
      #   results + JSON.parse(body)['body']
      #   keep_going = false unless 
      # end
    # end

    def get_boards
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      set_payload({
        source_url: "/pin/create/bookmarklet/?url=",
        pinFave: 1,
        description: "",
        data: data_json({
          filter: "all",
          field_set_key: "board_picker"
        })
      })
      set_uri subdomain(URLs[:get_boards])
      post
      JSON.parse(body)['resource_response']['data']['all_boards']
    end

    def create_board(board_name,privacy,options={})
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      set_uri subdomain(URLs[:create_board])
      set_payload({
        source_url: ('/%s/' % @username),
        module_path: 'App(module=[object Object])',
        data: data_json({
          name: board_name,
          privacy: privacy,
        }.merge(options))
      })
      post
      JSON.parse(body)['resource_response']['data']['id']
    end

    def follow_user(user_name, user_id)
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      set_uri subdomain(URLs[:follow_user])
      set_payload({
        source_url: ('/%s/' % user_name),
        module_path: 'App(module=[object Object], state_hasSpellCheck=false)',
        data: data_json({
          user_id: user_id
        })
      })
      post
      body
    end

    def unfollow_user(user_name,user_id)
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      set_uri subdomain(URLs[:unfollow_user])
      set_payload({
        source_url: ('/%s/' % user_name),
        data: data_json({
          user_id: user_id
        })
      })
      post
      body
    end

    def follow_board(user_name,board_name,board_id)
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      set_uri subdomain(URLs[:follow_board])
      set_payload({
        source_url: ('/%s/%s/' % [user_name,board_name]),
        data: data_json({
          board_id: board_id
        })
      })
      post
      body
    end

    def unfollow_board(user_name,board_name,board_id)
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      set_uri subdomain(URLs[:unfollow_board])
      set_payload({
        source_url: ('/%s/%s/' % [user_name,board_name]),
        data: data_json({
          board_id: board_id
        })
      })
      post
      body
    end

    def followers(username, bookmark_arg=nil, hffr=true)
      header 'X-CSRFToken', @login_cookies['csrftoken']
      set_cookies @login_cookies
      source_url = '/%s/followers' % username
      set_uri subdomain(URLs[:followers]) + query_params({
        source_url: source_url,
        data: data_json({
          hide_find_friends_rep: hffr,
          username: username
        })
      }.tap {|h| h.merge({bookmarks: [bookmark_arg]}) if bookmark_arg})
      get
      result = JSON.parse(body)
      results = []
      error = false
      loop do
        r = result['resource_response']['data']
        bookmark = result['resource']['options']['bookmarks'].first
        break if bookmark == '-end-'
        if r['resource_response']['error']
          error = true
          break
        end
        yield r if block_given?
        results += r
        set_uri subdomain(URLs[:followers]) + query_params({
          source_url: source_url,
          data: data_json({
            bookmarks: [bookmark],
            hide_find_friends_rep: hffr,
            username: username
          })
        })
        sleep 0.01
        get
        result = JSON.parse(body)
      end
      error ? [results,bookmark] : results
    end

    private

    def data_json(opts={})
      {
        options: opts,
        context: {}
      }.to_json
    end

    def subdomain(url)
    @sub ? '%s.%s' % [@sub, url] : url
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
        module_path: 'App>ModalManager>Modal>PinCreate>PinCreateBoardPicker>BoardPicker>SelectList(view_type=pinCreate, selected_section_index=undefined, selected_item_index=undefined, highlight_matched_text=true, suppress_hover_events=undefined, scroll_selected_item_into_view=true, select_first_item_after_update=false, item_module=[object Object])',
        data: data_json({
          is_buyable_pin: false,
          description: decode_html(Regex[:description] =~ body ? $1 : ''),
          link: (Regex[:link] =~ body ? $1 : ''),
          is_video: false,
          board_id: board_id,
          pin_id: pin_id
        })
      })
      set_uri subdomain(URLs[:repin])
      post
      JSON.parse(body)['resource_response']['data']['id']
    end
  end
end
